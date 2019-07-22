const rFund = artifacts.require("RewardFund")
const Token = artifacts.require("RoobeeToken");
const Web3 = require('web3');
const provider = new Web3.providers.HttpProvider('http://localhost:7545');
const web3 = new Web3(provider);
const truffleAssert = require('truffle-assertions');

contract("AssetsFactoryTest", async accounts => {

    it("should add category", async () => {
        let fund = await rFund.deployed();
        await fund.addCategory(1,100,1);
        let category = await fund.categories.call(1);
        assert.equal(category[0].words[0], 100);
        assert.equal(category[1].words[0], 1);
    });

    it("should pay reward", async () => {
        let fund = await rFund.deployed();
        let token = await Token.deployed();
        await token.mint(fund.address, 1000);
        await fund.payReward(1, accounts[1]);
        let balance1 = await token.balanceOf.call(accounts[1]);
        assert.equal(balance1, 100);
    });

    it("should revert with limit over", async () => {
        let fund = await rFund.deployed();
        let token = await Token.deployed();
        await truffleAssert.reverts(fund.payReward(1, accounts[1]), "limit over");
    });

    it("should change limit and amount", async () => {
        let fund = await rFund.deployed();
        await fund.changeCategoriesLimit(1,2);
        await fund.changeCategoriesAmount(1,150);
        let category = await fund.categories.call(1);
        assert.equal(category[0].words[0], 150);
        assert.equal(category[1].words[0], 2);
    });

    it("should pay 2nd reward", async () => {
        let fund = await rFund.deployed();
        let token = await Token.deployed();
        await fund.payReward(1, accounts[1]);
        let balance1 = await token.balanceOf.call(accounts[1]);
        assert.equal(balance1.words[0], 250);
    });

    it("should revert with limit over", async () => {
        let fund = await rFund.deployed();
        let token = await Token.deployed();
        await truffleAssert.reverts(fund.payReward(1, accounts[1]), "limit over");
    });

    it("should change limit", async () => {
        let fund = await rFund.deployed();
        await fund.changeCategoriesLimit(1,0);
        let category = await fund.categories.call(1);
        assert.equal(category[1].words[0], 0);
    });

    it("should pay 3d reward", async () => {
        let fund = await rFund.deployed();
        let token = await Token.deployed();
        await fund.payReward(1, accounts[1]);
        let balance1 = await token.balanceOf.call(accounts[1]);
        assert.equal(balance1.words[0], 400);
    });


    it("should revert with Ownable: caller is not the owner", async () => {
        let fund = await rFund.deployed();
        let token = await Token.deployed();
        await truffleAssert.reverts(fund.payReward(1, accounts[2], { from: accounts[2] }), "Ownable: caller is not the owner");
    });



});