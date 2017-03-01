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
#include <boost/filesystem.hpp>

#include "../BasicOperations/BasicOperations.h"
using namespace std;
using namespace boost::filesystem;

AnnotationProcessor::AnnotationProcessor() {
	// TODO Auto-generated constructor stub

}

AnnotationProcessor::~AnnotationProcessor() {
	// TODO Auto-generated destructor stub
}

void AnnotationProcessor::convertCSV2Txt(string trainBgFilePath,
		string trainEventFilePath, string testRefFilePath,
		vector<string> featureDirPaths, string trainTxtPath,
		string testTxtPath) {

	cout << "Parsing Feature Dir..." << endl;
	//map<videoId, videoPath>
	map<string, string> videoIdToPathMap;
	parseFeatureDirVecToMap(featureDirPaths, videoIdToPathMap);

	cout << "Converting for Train..." << endl;
	convertCSV2TxtTrain(trainBgFilePath, trainEventFilePath, videoIdToPathMap, trainTxtPath);
	cout << "Converting for Test..." << endl;
	convertCSV2TxtTest(testRefFilePath, videoIdToPathMap, testTxtPath);

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
		string trainTxtPath) {

	//map<path, label>
	map<string, int> pathToLabel;
	cout << "Parsing Bg..." << endl;
	parseTrainBg(trainBgFilePath, videoIdToPathMap, pathToLabel);
	cout << "Parsing Event..." << endl;
	parseTrainEvent(trainEventFilePath, videoIdToPathMap, pathToLabel);

	cout << "Outputing Annotations..." << endl;
	outputTxtAnnotations(pathToLabel, trainTxtPath, SHUFFLE);
}

void AnnotationProcessor::convertCSV2TxtTest(string testRefFilePath,
		const map<string, string>& videoIdToPathMap, string testTxtPath) {

	map<string, int> pathToLabel;
	cout << "Parsing Ref..." << endl;
	parseTestRef(testRefFilePath, videoIdToPathMap, pathToLabel);

	cout << "Outputing Annotations..." << endl;
	outputTxtAnnotations(pathToLabel, testTxtPath, FILE_TEMPLATE_ORDER, testRefFilePath, videoIdToPathMap);

}

void AnnotationProcessor::parseTrainBg(string trainBgFilePath,
		const map<string, string>& videoIdToPathMap,
		map<string, int>& pathToLabel) {

	ifstream trainBgFile(trainBgFilePath.c_str());
	string strLine;
	getline(trainBgFile, strLine);
	while(getline(trainBgFile, strLine)) {
		if(strLine == "" || strLine == "\n")
			continue;

		vector<string> strVec;
		BasicOperations::splitStringToVecDelimiter(strLine, strVec, ',');
		string videoId = strVec[0].substr(1, strVec[0].size() - 2);
		string videoPath = videoIdToPathMap.find(videoId)->second;

		assert(pathToLabel.find(videoPath) == pathToLabel.end());
		pathToLabel[videoPath] = 21;
	}
	trainBgFile.close();

}

void AnnotationProcessor::parseTrainEvent(string trainEventFilePath,
		const map<string, string>& videoIdToPathMap,
		map<string, int>& pathToLabel) {

	ifstream trainEventFile(trainEventFilePath.c_str());
	string strLine;
	getline(trainEventFile, strLine);
	while(getline(trainEventFile, strLine)) {
		if(strLine == "" || strLine == "\n")
			continue;

		vector<string> strVec;
		BasicOperations::splitStringToVecDelimiter(strLine, strVec, ',');
		string videoId = strVec[0].substr(1, strVec[0].size() - 2);
		int eventId = atoi(strVec[1].substr(2, strVec[1].size() - 3).c_str()) - 20;
		bool isPos = strVec[2] == "\"positive\"" ? true : false;

		//'Miss' as negatives
		//if(isPos) {
		string videoPath = videoIdToPathMap.find(videoId)->second;
		assert(pathToLabel.find(videoPath) == pathToLabel.end());
		if(isPos)
			pathToLabel[videoPath] = eventId;
		else
			pathToLabel[videoPath] = 21;
		//}
	}
	trainEventFile.close();

}

void AnnotationProcessor::parseTestRef(string testRefFilePath,
		const map<string, string>& videoIdToPathMap,
		map<string, int>& pathToLabel) {

	//map<videoId, labelSet>
	map<string, set<int> > videoIdToLabels;
	ifstream testRefFile(testRefFilePath.c_str());
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
			int eventId = atoi(strVecVideoIdEventId[1].substr(1, strVecVideoIdEventId[1].size() - 1).c_str()) - 20;
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

		string videoPath = videoIdToPathMap.find(videoId)->second;
		int label = 21;
		if(labelSet.size() != 0) {
			set<int>::const_iterator labelSetIt = labelSet.begin();
			label = *labelSetIt;
		}

		assert(pathToLabel.find(videoPath) == pathToLabel.end());
		pathToLabel[videoPath] = label;
	}

}

void AnnotationProcessor::outputTxtAnnotations(
		const map<string, int>& pathToLabel, string txtPath, Order order, string sortTemplateRefFile, const map<string, string>& videoIdToPath) {

	map<string, int>::const_iterator pathToLabelIt = pathToLabel.begin();
	vector<pair<string, int> > pathToLabelVec;

	if(order == ORIGIN)
		mapToVecOrigin(pathToLabel, pathToLabelVec);
	else if(order == SHUFFLE)
		mapToVecShuffle(pathToLabel, pathToLabelVec);
	else if(order == FILE_TEMPLATE_ORDER)
		mapToVecFileTemplate(pathToLabel, pathToLabelVec, sortTemplateRefFile, videoIdToPath);

	ofstream txtFile(txtPath.c_str());
	for(int count = 0; count < pathToLabelVec.size(); count++) {
		txtFile << pathToLabelVec[count].first << " " << pathToLabelVec[count].second << endl;
	}

	txtFile.close();

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

void AnnotationProcessor::mapToVecFileTemplate(
	const map<string, int>& pathToLabel,
	vector<pair<string, int> >& pathToLabelVec, string templateRefFilePath,
	const map<string, string>& videoIdToPath) {

	assert(templateRefFilePath != "");

	set<string> videoIdSet;
	ifstream refFile(templateRefFilePath.c_str());
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
		string videoPath = videoIdToPath.find(videoId)->second;

		pathToLabelVec.push_back(pair<string, int>(videoPath, pathToLabel.find(videoPath)->second));
	}
	refFile.close();

}
