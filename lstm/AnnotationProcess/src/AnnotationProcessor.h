/*
 * AnnotationProcessor.h
 *
 *  Created on: Feb 10, 2017
 *      Author: mengxi
 */

#ifndef ANNOTATIONPROCESSOR_H_
#define ANNOTATIONPROCESSOR_H_

#include <string>
#include <vector>
#include <map>
using namespace std;

enum Order {ORIGIN, SHUFFLE, FILE_TEMPLATE_ORDER};

class AnnotationProcessor {
public:
	AnnotationProcessor();
	virtual ~AnnotationProcessor();

	static void setEventIdOffsetAndEventNum(int eventIdOffset, int eventNum);

	static void convertCSV2Txt(
			string trainBgFilePath, string trainEventFilePath,
			string testRefFilePath,
			vector<string> featureDirPaths,
			string trainTxtPath,
			string testTxtPath,
			bool isOmmitBackground = false,
			string newTestRefFilePath = "");

private:
	static int eventIdOffset;

	static int eventNum;

	static void parseFeatureDirVecToMap(const vector<string>& featureDirPaths, map<string, string>& videoIdToPathMap);

	static void convertCSV2TxtTrain(
			string trainBgFilePath, string trainEventFilePath,
			const map<string, string>& videoIdToPathMap,
			string trainTxtPath,
			bool isOmmitBackground = false);

	static void convertCSV2TxtTest(
			string testRefFilePath,
			const map<string, string>& videoIdToPathMap,
			string testTxtPath,
			bool isOmmitBackground = false,
			string newTestRefFilePath = "");

	static void parseTrainBg(
			string trainBgFilePath,
			const map<string, string>& videoIdToPathMap,
			map<string, int>& pathToLabel);

	static void parseTrainEvent(
			string trainEventFilePath,
			const map<string, string>& videoIdToPathMap,
			map<string, int>& pathToLabel,
			bool isOmmitBackground = false);

	static void parseTestRef(
			string testRefFilePath,
			const map<string, string>& videoIdToPathMap,
			map<string, int>& pathToLabel,
			bool isOmmitBackground = false);

	static void outputTxtAnnotations(const map<string, int>& pathToLabel, string trainTxtPath,
			Order order = ORIGIN,
			string sortTemplateRefFile = "",
			const map<string, string>& videoIdToPath = map<string, string>(),
			string newRefFilePath = "");

	static void outputTestRef(const vector<pair<string, int> >& pathToLabelVec, string newRefPath);

	static void convertToTrialEventId(const vector<pair<string, int> >& pathToLabelVec, vector<pair<string, int> >& trialEventIdVec);

	static void mapToVecOrigin(const map<string, int>& pathToLabel, vector<pair<string, int> >& pathToLabelVec);

	static void mapToVecShuffle(const map<string, int>& pathToLabel, vector<pair<string, int> >& pathToLabelVec);

	static void mapToVecFileTemplate(
			const map<string, int>& pathToLabel,
			vector<pair<string, int> >& pathToLabelVec,
			string templateRefFilePath,
			const map<string, string>& videoIdToPath);
};

#endif /* ANNOTATIONPROCESSOR_H_ */
