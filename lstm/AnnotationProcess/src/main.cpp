#include "AnnotationProcessor.h"
#include <cstdlib>

int main(int argc, char* argv[]) {
	string trainBgFilePath = argv[1];
	string trainEventFilePath = argv[2];
	string testRefFilePath = argv[3];
	string trainTxtPath = argv[4];
	string testTxtPath = argv[5];
	int featureDirNum = atoi(argv[6]);

	vector<string> featureDirPath;
	for(int countFeatureDir = 0; countFeatureDir < featureDirNum; countFeatureDir++)
		featureDirPath.push_back(argv[7 + countFeatureDir]);

	// eventIdOffset: firstEventId - eventIdOffset = 1
	int eventIdOffset = atoi(argv[7 + featureDirNum]);
	int eventNum = atoi(argv[8 + featureDirNum]);
	bool isOmmitBackground = atoi(argv[9 + featureDirNum]) == 0 ? false : true;
	string newTestRefFilePath = argv[10 + featureDirNum];

	AnnotationProcessor::setEventIdOffsetAndEventNum(eventIdOffset, eventNum);
	AnnotationProcessor::convertCSV2Txt(
			trainBgFilePath, trainEventFilePath,
			testRefFilePath,
			featureDirPath,
			trainTxtPath, testTxtPath,
			isOmmitBackground, newTestRefFilePath);

	return 0;
}
