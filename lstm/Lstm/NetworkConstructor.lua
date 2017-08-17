-- Author: Mengxi
-- Date: 2017.8.14

require 'nn'
require 'rnn'

local NetworkConstructor = {}

-- Input/Output format: time x batchSize x featDim
local function constructLstmLayer(inputDim, hiddenDim)
	local lstm = nn.SeqLSTM(inputDim, hiddenDim)
	lstm.maskzero = true
	
	return lstm
end

-- Input/Output format: time x batchSize x featDim
local function constructLSTM(inputDim, hiddenDim, outputDim)
	local net = nn.Sequential()
	local lstmLayer = constructLstmLayer(inputDim, hiddenDim)
	net:add(lstmLayer)
	
	net:add(nn.Bottle(nn.MaskZero(nn.Linear(hiddenDim, outputDim), 1)))
	 
	return net
end
NetworkConstructor.constructLSTM = constructLSTM

return NetworkConstructor
