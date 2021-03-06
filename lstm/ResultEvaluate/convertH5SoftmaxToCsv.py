# Original Author: Na
# Refactor Author: Mengxi
# Date: 2017.8.14
import numpy as np
import h5py
import sys
import math
'''
"TrialID","Score"
"000069.E021","0.206144"
"000069.E022","0.120005"
"000069.E023","0.112380"
"000069.E024","0.295885"
"000069.E025","0.223154"
"000069.E026","0.144167"
"000069.E027","0.116130"
"000069.E028","0.125871"
"000069.E029","0.198441"
"000069.E030","0.105077"
"000069.E031","0.130933"
"000069.E032","0.103783"
"000069.E033","0.073845"
"000069.E034","0.062903"
"000069.E035","0.143251"
"000069.E036","0.158367"
"000069.E037","0.264287"
"000069.E038","0.236143"
"000069.E039","0.061686"
"000069.E040","0.115425"
"000197.E021","0.122825"
"000197.E022","0.215184"
"000197.E023","0.120713"
"000197.E024","0.241060"
"000197.E025","0.205189"
"000197.E026","0.180249"
"000197.E027","0.179011"
"000197.E028","0.103795"
"000197.E029","0.222974"
"000197.E030","0.119268"
"000197.E031","0.093359"
"000197.E032","0.071569"
"000197.E033","0.083485"
"000197.E034","0.065199"
"000197.E035","0.092222"
"000197.E036","0.118098"
"000197.E037","0.258427"
"000197.E038","0.148629"
"000197.E039","0.112379"
"000197.E040","0.157834"
'''

resultH5Path = sys.argv[1]
refCSVPath = sys.argv[2]
resultCSVPath = sys.argv[3]
eventIdOffset = int(sys.argv[4])
isSoftmaxIncludeBackground = bool(int(sys.argv[5]))

print "Converting " + resultH5Path

with h5py.File(resultH5Path, 'r') as softmaxFile:
	#softmaxMat: sampleNum x targetNum
	softmaxMat = softmaxFile.get('data') #Mengxi says it's strange to call the softmax data 'data'
	softmaxMat = np.array(softmaxMat)
	
targetClassNum = softmaxMat.shape[1]
if isSoftmaxIncludeBackground:
	targetClassNum = targetClassNum - 1
print "TargetClassNum (not include 'Background'): ", targetClassNum
print "SampleNum: ", softmaxMat.shape[0]

refCSVFile = open(refCSVPath, 'r')
with open(resultCSVPath, 'w') as resultCSVFile:
	resultCSVFile.write("\"TrialID\",\"Targ\"\n")

# Get the clipId from the 'ref.csv' file
clipIdList = []
refCSVOneLine = refCSVFile.readline()
trialCount = 0
refCSVOneLine = refCSVFile.readline()
while refCSVOneLine:
	if trialCount % targetClassNum == 0:
		clipIdList.append(refCSVOneLine.split('.')[0][1:])
	trialCount = trialCount + 1
	refCSVOneLine = refCSVFile.readline()
refCSVFile.close()

assert len(clipIdList) == softmaxMat.shape[0]

for sampleIdx, clipId in enumerate(clipIdList): 
	with open(resultCSVPath, 'a') as resultCSVFile:
		for eventId in range(0, targetClassNum):        
			prob = softmaxMat[sampleIdx, eventId]
			resultCSVFile.write("\"" + clipId + ".E0" + str(eventId + eventIdOffset) + "\", \"" + str(prob) + "\"" + "\n")


