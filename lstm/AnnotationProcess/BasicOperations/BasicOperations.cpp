#include "BasicOperations.h"

#include <fstream>
using namespace std;
using namespace boost::filesystem;


BasicOperations::BasicOperations(void)
{
}


BasicOperations::~BasicOperations(void)
{
}

void BasicOperations::splitStringToVec(string str, vector<string>& strVec) {
	istringstream strStream(str);
	string strItem;
	while(getline(strStream, strItem, ' ')){
		if(strItem == "")
			continue;

		strVec.push_back(strItem);
	}
}

void BasicOperations::splitStringToVecDelimiter(string str,
		vector<string>& strVec, char delimiter) {

	istringstream strStream(str);
	string strItem;
	while(getline(strStream, strItem, delimiter)){
		if(strItem == "")
			continue;

		strVec.push_back(strItem);
	}

}

string BasicOperations::convertNumToStr( int num ) 
{
	ostringstream convert;
	convert << num;

	return convert.str();
}


void BasicOperations::getPathOfFileInDir(string dirPath,
		vector<path>& filePathVec) {

	path dirPathBoost(dirPath);
	directory_iterator dirIt(dirPathBoost);
	directory_iterator eod;
	copy(dirIt, eod, back_inserter(filePathVec));
	sort(filePathVec.begin(), filePathVec.end());

}

void BasicOperations::eliminateDuplicates(vector<int>& vec) {
	set<int> mySet;
	for(int countVec = 0; countVec < vec.size(); countVec++) {
		mySet.insert(vec[countVec]);
	}

	vec.clear();
	set<int>::iterator mySetIt = mySet.begin();
	for(; mySetIt != mySet.end(); mySetIt++) {
		vec.push_back(*mySetIt);
	}
}

string BasicOperations::convertNumToStrFloat(float num) {
	ostringstream convert;
	convert << num;

	return convert.str();
}

string BasicOperations::convertNumToStrLong(unsigned long long num) {

	ostringstream convert;
	convert << num;

	return convert.str();
}

void BasicOperations::splitDir(string srcDir, string desDir, int splitNum) {

	vector<path> srcFilePaths;
	BasicOperations::getPathOfFileInDir(srcDir, srcFilePaths);
	int interval = 0;
	if(srcFilePaths.size() % splitNum == 0)
		interval = srcFilePaths.size() / splitNum;
	else
		interval = srcFilePaths.size() / splitNum + 1;

	string newDirPath = "";
	for(int count = 0; count < srcFilePaths.size(); count++) {
		if(count % interval == 0) {
			newDirPath = desDir + BasicOperations::convertNumToStr(count / interval) + "/";
			create_directory(newDirPath);
		}

		copy_file(srcFilePaths[count], newDirPath + srcFilePaths[count].filename().string());
		cout << "Completed: " << srcFilePaths[count].filename().string() << endl;
	}

}

void BasicOperations::makeCombination(const set<int>& nonZeroSet,
		set<pair<int, int> >& combination) {

	set<int>::const_iterator nonZeroSetIt1 = nonZeroSet.begin();
	set<int>::const_iterator nonZeroSetIt2 = nonZeroSet.begin();

	for(; nonZeroSetIt1 != nonZeroSet.end(); nonZeroSetIt1++)
		for(; nonZeroSetIt2 != nonZeroSet.end(); nonZeroSetIt2++) {
			if(*nonZeroSetIt1 == *nonZeroSetIt2)
				continue;
			int big;
			int small;
			if(*nonZeroSetIt1 > *nonZeroSetIt2) {
				big = *nonZeroSetIt1;
				small = *nonZeroSetIt2;
			}
			else {
				big = *nonZeroSetIt2;
				small = *nonZeroSetIt1;
			}

			pair<int, int> newPair(small, big);
			combination.insert(newPair);
		}

}

void BasicOperations::convertStrVecToIntVec(const vector<string>& strVec,
		vector<int>& idxVec) {

	idxVec = vector<int>(strVec.size());
	for(int count = 0; count < strVec.size(); count++) {
		idxVec[count] = atoi(strVec[count].c_str());
	}

}

void BasicOperations::convertStrVecToFloatVec(const vector<string>& strVec,
		vector<float>& floatVec) {

	floatVec = vector<float>(strVec.size());
	for(int count = 0; count < strVec.size(); count++) {
		floatVec[count] = atof(strVec[count].c_str());
	}

}

bool BasicOperations::lessThanPairBySecond(const pair<int, float>& lhs,
		const pair<int, float>& rhs) {

	if(lhs.second < rhs.second)
		return true;
	else
		return false;

}

void BasicOperations::filterFileSuffix(vector<path>& paths, string suffix) {

	vector<path> pathsFiltered;
	for(int count = 0; count < paths.size(); count++) {
		string currentSuffix = paths[count].filename().extension().string();
		if(currentSuffix != suffix)
			pathsFiltered.push_back(paths[count]);
	}
	paths = pathsFiltered;

}

string BasicOperations::queryNameFromPyrToResultList(string queryName) {

	path queryNamePathPyr(queryName);
	string queryNameResult = queryNamePathPyr.stem().stem().stem().string() + ".softWordIdx";

	return queryNameResult;

}

void BasicOperations::readWholeFileAsString(string filePath,
		string& str) {

	ifstream inFile(filePath.c_str());
	stringstream strStream;
	strStream << inFile.rdbuf();

	str = strStream.str();

	inFile.close();
}
