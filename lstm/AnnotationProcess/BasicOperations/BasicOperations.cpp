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

void BasicOperations::readWholeFileAsString(string filePath,
		string& str) {

	std::ifstream inFile(filePath.c_str());
	stringstream strStream;
	strStream << inFile.rdbuf();

	str = strStream.str();

	inFile.close();
}
