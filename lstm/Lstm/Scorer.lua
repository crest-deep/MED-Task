-- Author: Mengxi
-- Date: 2017.8.14

local Scorer = {}

-- miniSoftMax: time x batchNum x featDim
local function takeAvgStep(miniSoftMax, miniBatchLen)
	assert(#miniBatchLen == miniSoftMax:size(2))

	-- check zero masking validity
	for countSeq = 1, miniSoftMax:size(2) do
		assert(miniBatchLen[countSeq] <= miniSoftMax:size(1))
		if miniBatchLen[countSeq] < miniSoftMax:size(1) then
			assert(miniSoftMax[miniBatchLen[countSeq] + 1][countSeq]:sum() == 0)
		end
	end
	
	local miniSoftMaxAvg = miniSoftMax:sum(1)[1]
	for countSeq = 1, miniSoftMaxAvg:size(1) do
		miniSoftMaxAvg[countSeq] = miniSoftMaxAvg[countSeq] / miniBatchLen[countSeq]
	end
	
	return miniSoftMaxAvg
end
Scorer.takeAvgStep = takeAvgStep

return Scorer