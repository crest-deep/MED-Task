/*
 * AnnotationProcessor.cpp
 *
 *  Created on: Feb 10, 2017
 *      Author: mengxi
 */

#include "AnnotationProcessor.h"

#include <map>
#include <fstream>
#include <iostream>
#include <iomanip>
#include <boost/filesystem.hpp>

#include "../BasicOperations/BasicOperations.h"
using namespace std;
using namespace boost::filesystem;

int AnnotationProcessor::eventIdOffset = 0;

int AnnotationProcessor::eventNum = 10;

AnnotationProcessor::AnnotationProcessor() {
	// TODO Auto-generated constructor stub

}

AnnotationProcessor::~AnnotationProcessor() {
	// TODO Auto-generated destructor stub
}

void AnnotationProcessor::convertCSV2Txt(string trainBgFilePath,
		string trainEventFilePath, string testRefFilePath,
		vector<string> featureDirPaths, string trainTxtPath,
		string testTxtPath, bool isOmitBackgroundVideo, string newTestRefFilePath) {

	cout << "Parsing Feature Dir..." << endl;
	//map<videoId, videoPath>
	map<string, string> videoIdToPathMap;
	parseFeatureDirVecToMap(featureDirPaths, videoIdToPathMap);

	cout << "Converting for Train..." << endl;
	convertCSV2TxtTrain(trainBgFilePath, trainEventFilePath, videoIdToPathMap, trainTxtPath, isOmitBackgroundVideo);
	cout << "Converting for Test..." << endl;
	convertCSV2TxtTest(testRefFilePath, videoIdToPathMap, testTxtPath, isOmitBackgroundVideo, newTestRefFilePath);

}

void AnnotationProcessor::parseFeatureDirVecToMap(
		const vector<string>& featureDirPaths,
		map<string, string>& videoIdToPathMap) {

	for(int countFeatureDir = 0; countFeatureDir < featureDirPaths.size(); countFeatureDir++) {
		cout << "Parsing Dir: " << featureDirPaths[countFeatureDir] << endl;

		vector<path> currentFeaturePaths;
		BasicOperations::getPathOfFileInDir(featureDirPaths[countFeatureDir], currentFeaturePaths);
		//string parentPath = featureDirPaths[countFeatureDir];

		for(int countPath = 0; countPath < currentFeaturePaths.size(); countPath++) {
			string videoId = currentFeaturePaths[countPath].stem().string();
			assert(videoIdToPathMap.find(videoId) == videoIdToPathMap.end());

			videoIdToPathMap[videoId] = currentFeaturePaths[countPath].string();
		}
	}

}

void AnnotationProcessor::convertCSV2TxtTrain(string trainBgFilePath,
		string trainEventFilePath, const map<string, string>& videoIdToPathMap,
		string trainTxtPath, bool isOmitBackgroundVideo) {

	//map<path, label>
	map<string, int> pathToLabel;
	cout << "Parsing Bg..." << endl;
	if(!isOmitBackgroundVideo)
		parseTrainBg(trainBgFilePath, videoIdToPathMap, pathToLabel);

	cout << "Parsing Event..." << endl;
	parseTrainEvent(trainEventFilePath, videoIdToPathMap, pathToLabel, isOmitBackgroundVideo);

	cout << "Outputing Annotations..." << endl;
	outputTxtAnnotations(pathToLabel, trainTxtPath, SHUFFLE);
}

void AnnotationProcessor::convertCSV2TxtTest(string testRefFilePath,
		const map<string, string>& videoIdToPathMap, string testTxtPath, bool isOmmitBackground,
		string newTestRefPath) {

	map<string, int> pathToLabel;
	cout << "Parsing Ref..." << endl;
	parseTestRef(testRefFilePath, videoIdToPathMap, pathToLabel, isOmmitBackground);

	cout << "Outputing Annotations..." << endl;

	outputTxtAnnotations(
			pathToLabel, testTxtPath,
			FILE_TEMPLATE_ORDER, testRefFilePath, videoIdToPathMap, newTestRefPath);

}

void AnnotationProcessor::parseTrainBg(string trainBgFilePath,
		const map<string, string>& videoIdToPathMap,
		map<string, int>& pathToLabel) {

	std::ifstream trainBgFile(trainBgFilePath.c_str());
	string strLine;
	getline(trainBgFile, strLine);
	while(getline(trainBgFile, strLine)) {
		if(strLine == "" || strLine == "\n")
			continue;

		vector<string> strVec;
		BasicOperations::splitStringToVecDelimiter(strLine, strVec, ',');
		string videoId = strVec[0].substr(1, strVec[0].size() - 2);

		if(videoIdToPathMap.find(videoId) == videoIdToPathMap.end()) {
			cout << "Omit the video since not found in featur dir: " << videoId << endl;
			continue;
		}
		string videoPath = videoIdToPathMap.find(videoId)->second;

		assert(pathToLabel.find(videoPath) == pathToLabel.end());
		pathToLabel[videoPath] = AnnotationProcessor::eventNum + 1;
	}
	trainBgFile.close();

}

void AnnotationProcessor::parseTrainEvent(string trainEventFilePath,
		const map<string, string>& videoIdToPathMap,
		map<string, int>& pathToLabel, bool isOmitBackgroundVideo) {

	ifstream trainEventFile(trainEventFilePath.c_str());
	string strLine;
	getline(trainEventFile, strLine);
	while(getline(trainEventFile, strLine)) {
		if(strLine == "" || strLine == "\n")
			continue;

		vector<string> strVec;
		BasicOperations::splitStringToVecDelimiter(strLine, strVec, ',');
		string videoId = strVec[0].substr(1, strVec[0].size() - 2);
		int eventId = atoi(strVec[1].substr(2, strVec[1].size() - 3).c_str()) - AnnotationProcessor::eventIdOffset;
		bool isPos = strVec[2] == "\"positive\"" ? true : false;

		if(videoIdToPathMap.find(videoId) == videoIdToPathMap.end()) {
			cout << "Omit the video since not found in featur dir: " << videoId << endl;
			continue;
		}

		//'Miss' as negatives
		string videoPath = videoIdToPathMap.find(videoId)->second;
		assert(pathToLabel.find(videoPath) == pathToLabel.end());
		if(isPos)
			pathToLabel[videoPath] = eventId;
		else if(!isOmitBackgroundVideo)
			pathToLabel[videoPath] = AnnotationProcessor::eventNum + 1;

	}
	trainEventFile.close();

}

void AnnotationProcessor::parseTestRef(string testRefFilePath,
		const map<string, string>& videoIdToPathMap,
		map<string, int>& pathToLabel, bool isOmmitBackground) {

	//map<videoId, labelSet>
	map<string, set<int> > videoIdToLabels;
	std::ifstream testRefFile(testRefFilePath.c_str());
	string strLine;
	getline(testRefFile, strLine);
	while(getline(testRefFile, strLine)) {
		if(strLine == "" || strLine == "\n")
			continue;

		vector<string> strVec;
		BasicOperations::splitStringToVecDelimiter(strLine, strVec, ',');
		string strVideoIdEventId = strVec[0].substr(1, strVec[0].size() - 2);
		bool isTrue = strVec[1].substr(1, strVec[1].size() - 2) == "y" ? true : false;
		vector<string> strVecVideoIdEventId;
		BasicOperations::splitStringToVecDelimiter(strVideoIdEventId, strVecVideoIdEventId, '.');
		string videoId = "HVC" + strVecVideoIdEventId[0];
		videoIdToLabels[videoId];

		if(isTrue) {
			int eventId = atoi(strVecVideoIdEventId[1].substr(1, strVecVideoIdEventId[1].size() - 1).c_str()) - AnnotationProcessor::eventIdOffset;
			videoIdToLabels[videoId].insert(eventId);
		}

	}
	testRefFile.close();

	//Parse into 'pathToLabel'
	map<string, set<int> >::const_iterator videoIdToLabelsIt = videoIdToLabels.begin();
	for(; videoIdToLabelsIt != videoIdToLabels.end(); videoIdToLabelsIt++) {
		string videoId = videoIdToLabelsIt->first;
		const set<int>& labelSet = videoIdToLabelsIt->second;
		assert(labelSet.size() <= 1);

		if(videoIdToPathMap.find(videoId) == videoIdToPathMap.end()) {
			cout << "Omit the video since not found in feature dir: " << videoId << endl;
			continue;
		}

		string videoPath = videoIdToPathMap.find(videoId)->second;

		int label = AnnotationProcessor::eventNum + 1;
		if(labelSet.size() != 0) {
			set<int>::const_iterator labelSetIt = labelSet.begin();
			label = *labelSetIt;
		}

		assert(pathToLabel.find(videoPath) == pathToLabel.end());

		if(label == AnnotationProcessor::eventNum + 1 && isOmmitBackground)
			continue;

		pathToLabel[videoPath] = label;
	}

	cout << "PathToLabel Size: " << pathToLabel.size() << endl;

}

void AnnotationProcessor::outputTxtAnnotations(
		const map<string, int>& pathToLabel,
		string txtPath,
		Order order,
		string sortTemplateRefFile,
		const map<string, string>& videoIdToPath,
		string newRefPath) {

	map<string, int>::const_iterator pathToLabelIt = pathToLabel.begin();
	vector<pair<string, int> > pathToLabelVec;

	if(order == ORIGIN)
		mapToVecOrigin(pathToLabel, pathToLabelVec);
	else if(order == SHUFFLE)
		mapToVecShuffle(pathToLabel, pathToLabelVec);
	else if(order == FILE_TEMPLATE_ORDER)
		mapToVecFileTemplate(pathToLabel, pathToLabelVec, sortTemplateRefFile, videoIdToPath);

	std::ofstream txtFile(txtPath.c_str());
	for(int count = 0; count < pathToLabelVec.size(); count++) {
		txtFile << pathToLabelVec[count].first << " " << pathToLabelVec[count].second << endl;
	}
	txtFile.close();

	if(newRefPath != "") {
		outputTestRef(pathToLabelVec, newRefPath);
	}

}

void AnnotationProcessor::outputTestRef(
		const vector<pair<string, int> >& pathToLabelVec, string newRefPath) {
	vector<pair<string, int> > trialEventIdVec;
	convertToTrialEventId(pathToLabelVec, trialEventIdVec);

	std::ofstream newRefFile(newRefPath.c_str());
	newRefFile << "\"TrialID\",\"Targ\"" << endl;
	for(int countTrialVec = 0; countTrialVec < trialEventIdVec.size(); countTrialVec++) {
		string trialVideoId = trialEventIdVec[countTrialVec].first;
		int eventId = trialEventIdVec[countTrialVec].second;

		for(int countEvent = 1; countEvent <= AnnotationProcessor::eventNum; countEvent++) {
			newRefFile << "\"" << trialVideoId << ".";

			newRefFile << "E" << setfill('0') << setw(3) << countEvent + AnnotationProcessor::eventIdOffset;
			newRefFile.copyfmt(std::ios(NULL));
			newRefFile << "\"" << ",";

			newRefFile << "\"";
			if(countEvent + AnnotationProcessor::eventIdOffset == eventId)
				newRefFile << "y";
			else
				newRefFile << "n";
			newRefFile << "\"";
			newRefFile << endl;
		}
	}
	newRefFile.close();
}

void AnnotationProcessor::convertToTrialEventId(
		const vector<pair<string, int> >& pathToLabelVec,
		vector<pair<string, int> >& trialEventIdVec) {

	for(int countVec = 0; countVec < pathToLabelVec.size(); countVec++) {
		string videoPath = pathToLabelVec[countVec].first;
		int label = pathToLabelVec[countVec].second;

		string trialVideoId = path(videoPath).stem().string().substr(3, 6);
		int eventId = label + AnnotationProcessor::eventIdOffset;

		trialEventIdVec.push_back(pair<string, int>(trialVideoId, eventId));
	}

}

void AnnotationProcessor::mapToVecOrigin(const map<string, int>& pathToLabel,
	vector<pair<string, int> >& pathToLabelVec) {

	map<string, int>::const_iterator pathToLabelIt = pathToLabel.begin();
	for(; pathToLabelIt != pathToLabel.end(); pathToLabelIt++) {
		pathToLabelVec.push_back(pair<string, int>(pathToLabelIt->first, pathToLabelIt->second));
	}

}

void AnnotationProcessor::mapToVecShuffle(const map<string, int>& pathToLabel,
	vector<pair<string, int> >& pathToLabelVec) {

	mapToVecOrigin(pathToLabel, pathToLabelVec);
	random_shuffle(pathToLabelVec.begin(), pathToLabelVec.end());

}

void AnnotationProcessor::setEventIdOffsetAndEventNum(int eventIdOffset,
		int eventNum) {
	AnnotationProcessor::eventNum = eventNum;
	AnnotationProcessor::eventIdOffset = eventIdOffset;
}


void AnnotationProcessor::mapToVecFileTemplate(
	const map<string, int>& pathToLabel,
	vector<pair<string, int> >& pathToLabelVec, string templateRefFilePath,
	const map<string, string>& videoIdToPath) {

	assert(templateRefFilePath != "");

	set<string> videoIdSet;
	std::ifstream refFile(templateRefFilePath.c_str());
	string strLine = "";
	getline(refFile, strLine);
	while(getline(refFile, strLine)) {
		if(strLine == "" || strLine == "\n")
			continue;


		vector<string> strVec;
		BasicOperations::splitStringToVecDelimiter(strLine, strVec, ',');
		string strVideoIdEventId = strVec[0].substr(1, strVec[0].size() - 2);
		vector<string> strVecVideoIdEventId;
		BasicOperations::splitStringToVecDelimiter(strVideoIdEventId, strVecVideoIdEventId, '.');
		string videoId = "HVC" + strVecVideoIdEventId[0];

		if(videoIdSet.find(videoId) != videoIdSet.end())
			continue;

		videoIdSet.insert(videoId);

		if(videoIdToPath.find(videoId) == videoIdToPath.end()) {
			cout << "Not found video path when sorting using ref template: " << videoId << endl;
			continue;
		}

		string videoPath = videoIdToPath.find(videoId)->second;

		if(pathToLabel.find(videoPath) == pathToLabel.end()) {
			cout << "Not found video label for (maybe it's filtered as 'background'): " << videoPath << endl;
			continue;
		}

		pathToLabelVec.push_back(pair<string, int>(videoPath, pathToLabel.find(videoPath)->second));

	}
	refFile.close();

}
