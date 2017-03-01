--sequence x batch x featdim
--right-aligned
require 'cutorch'
require 'cunn'
require 'rnn'
require 'optim'
require 'hdf5'

local testAnnotationPath = arg[1]
local testNum = tonumber(arg[2])

local featdim = tonumber(arg[3])
local seqLengthMax = tonumber(arg[4])
local numTargetClasses = tonumber(arg[5])

local modelPath = arg[6]
local batchSize = tonumber(arg[7])

local outputPath = arg[8]

local gpuId = tonumber(arg[9])

cutorch.setDevice(gpuId + 1)

local timer = nil
local model = nil
timer = torch.Timer()
print("Loading model...")
print(modelPath)
model = torch.load(modelPath)
print("Model Loaded...")

--model:cuda()

local bactchseqLenMax = 0
local bactchseqLens = torch.Tensor(batchSize):fill(0)
local feattemp = torch.Tensor(batchSize, seqLengthMax, featdim):fill(0)
local labelbatch = torch.Tensor(batchSize):fill(0)
local targets = {}
local linenum = 0

local finalRes = torch.Tensor(testNum, numTargetClasses):fill(0)
for line in io.lines(testAnnotationPath) do
	linenum = linenum + 1
	print(linenum)
	local i = linenum % batchSize
	if i == 0 then 
		i = batchSize 
	end
	local featpath = line:split(' ')[1]
	local labeli = line:split(' ')[2]
	labelbatch[i] = tonumber(labeli)

	--dirs
	local myFile = hdf5.open(featpath, 'r')
	local data = myFile:read('feature'):all()
	bactchseqLens[i] = data:size(1)
	if bactchseqLens[i] > seqLengthMax then
		data = data[{{1,seqLengthMax}}]
		bactchseqLens[i] = seqLengthMax
	end
	feattemp[i][{{1,bactchseqLens[i]}, {}}] = data

	if (i == batchSize) then
		--for last batch
		bactchseqLenMax = torch.max(bactchseqLens)
		local input = {}  
		local seqPadding = torch.Tensor(batchSize):fill(bactchseqLenMax) - bactchseqLens
		----right-aligned, padding zero in the left
		for seq = 1, bactchseqLenMax do
			local forOneTimeStep = torch.Tensor(batchSize,featdim):fill(0)
			local labeltemp = torch.Tensor(batchSize):fill(0)
			forOneTimeStep = forOneTimeStep:cuda()
			labeltemp = labeltemp:cuda()
			for batchi = 1, batchSize do
				if seqPadding[batchi] < seq then
					forOneTimeStep[batchi] = feattemp[batchi][seq-seqPadding[batchi]]
					labeltemp[batchi] = labelbatch[batchi]
				end
			end
			table.insert(input,forOneTimeStep)
			table.insert(targets, labeltemp)
		end
		----RNN
		local output = model:forward(input)
	
		for batchj = 1,batchSize do
			for seqj = seqPadding[batchj]+1, bactchseqLenMax do
				finalRes[linenum-batchSize+batchj] = finalRes[linenum-batchSize+batchj] + output[seqj][batchj]:exp():double()
			end
			finalRes[linenum-batchSize+batchj] = finalRes[linenum-batchSize+batchj] / bactchseqLens[batchj]
		end

		--for new batch
		bactchseqLenMax = 0
		bactchseqLens = torch.Tensor(batchSize):fill(0)
		feattemp = torch.Tensor(batchSize,seqLengthMax,featdim):fill(0)
		labelbatch = torch.Tensor(batchSize):fill(0)
		targets = {}
	end
end
io.input():close()
--rest
local restnum = testNum % batchSize
bactchseqLenMax = torch.max(bactchseqLens)
local input = {}  
local seqPadding = torch.Tensor(batchSize):fill(bactchseqLenMax) - bactchseqLens
for seq = 1, bactchseqLenMax do
	local forOneTimeStep = torch.Tensor(restnum,featdim):fill(0)
	local labeltemp = torch.Tensor(restnum):fill(0)
	forOneTimeStep = forOneTimeStep:cuda()
	labeltemp = labeltemp:cuda()
	for batchi = 1, restnum do
		if seqPadding[batchi] < seq then
			forOneTimeStep[batchi] = feattemp[batchi][seq-seqPadding[batchi]]
			labeltemp[batchi] = labelbatch[batchi]
		end
	end
	table.insert(input,forOneTimeStep)
	table.insert(targets, labeltemp)
end
local output = model:forward(input)
for batchj = 1,restnum do
	for seqj = seqPadding[batchj] + 1,bactchseqLenMax do
		finalRes[testNum - restnum + batchj] = finalRes[testNum - restnum+batchj] + output[seqj][batchj]:exp():double()
	end
	finalRes[testNum - restnum + batchj] = finalRes[testNum - restnum + batchj] / bactchseqLens[batchj]
end

local outfile = hdf5.open(outputPath, 'w')
outfile:write('data', finalRes)	
outfile:close()
print('Time elapsed: ' .. timer:time().real .. ' seconds')
--end

