#include <vector>
#include <iostream>
class Solution {
public:
    std::vector<int> twoSum(std::vector<int>& nums, int target) {
        std::vector<int> res;
        if(nums.size() == 0)
            return res;
        for(int i = 0; i < nums.size() - 1; i++){
            for(int j = i + 1; j < nums.size(); j++){
                if (nums[i] + nums[j] == target)
                {
                    return {i, j};
                }
            }
        }
        return res;
    }
};


int main(){
    Solution s1;
    std::vector<int> input = {2,5,5,11};
    std::vector<int> res = s1.twoSum(input, 10);
    std::cout << '[' << res[0] << ',' << res[1] << ']';
}