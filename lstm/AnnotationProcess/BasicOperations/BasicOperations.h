#ifndef BASICOPERATIONS_H_
#define BASICOPERATIONS_H_

#include <string>
#include <vector>
#include <sstream>
#include <set>
#include <boost/filesystem.hpp>
#include <iostream>
using namespace std;


class BasicOperations
{
public:
	BasicOperations(void);
	~BasicOperations(void);

	static void splitStringToVec(string str, vector<string>& strVec);

	static void splitStringToVecDelimiter(string str, vector<string>& strVec, char delimiter);

	static string convertNumToStr( int num );

	static string convertNumToStrLong(unsigned long long num);

	static string convertNumToStrFloat(float num);

	static void getPathOfFileInDir(string dirPath, vector<boost::filesystem::path>& filePathVec);

	static void eliminateDuplicates(vector<int>& wordIdxVec);

	static void splitDir(string srcDir, string desDir, int splitNum);

	static void makeCombination(const set<int>& nonZeroSet, set< pair<int, int> >& combination);

	static void convertStrVecToIntVec(const vector<string>& strVec, vector<int>& intVec);

	static void convertStrVecToFloatVec(const vector<string>& strVec, vector<float>& floatVec);

	static bool lessThanPairBySecond(const pair<int, float>& lhs, const pair<int, float>& rhs);

	static void filterFileSuffix(vector<boost::filesystem::path>& paths, string suffix);

	static string queryNameFromPyrToResultList(string queryName);

	static void readWholeFileAsString(string filePath, string& str);

};

#endif
