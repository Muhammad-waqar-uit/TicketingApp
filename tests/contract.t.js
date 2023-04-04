const { inputToConfig } = require('@ethereum-waffle/compiler');
const {expect} =require('chai');


describe("Token Contract",function(){
    let Token;
    let hardhatToken;
    let owner;
    let add1;
    let add2;
    let addrs;
//before each test this this will be excuted to avoid any dublication of code lines
//hooks in mocha
    beforeEach(async function(){
        Token=await ethers.getContractFactory("Token");
        [owner,add1,add2,...addrs]=await ethers.getSigners();
        hardhatToken=await Token.deploy();
    });
describe("Deployement",function(){
    it("Should return if the right owner",async function(){
        expect(await hardhatToken.owner()).to.equal(owner.address);
    });

    it("Should assign total supply of tokens to the owner ",async function(){
        const ownerbalance=await hardhatToken.balancesOf(owner.address);

        expect(await hardhatToken.supply()).to.equal(ownerbalance);
    });

    describe("Transaction",function(){
        it('Should transfer tokens between accounts',async function(){
            //owner to address1 transfer
            await hardhatToken.transer(add1.address,5);
            const addr1balance=await hardhatToken.balancesOf(add1.address);
            expect(addr1balance).to.equal(5);

            await hardhatToken.connect(add1).transer(add2.address,5);
            const address2balance=await hardhatToken.balancesOf(add2.address);
            expect(address2balance).to.equal(5);
        })
        it("it shoulf fail if does not have tokens",async function(){
            const initalownerbalance=await hardhatToken.balancesOf(owner.address);
            await expect(hardhatToken.connect(add1).transer(owner.address,1)).to.be.revertedWith("Not enough tokens");//zero token so no transfer
            expect(await hardhatToken.balancesOf(owner.address)).to.equal(initalownerbalance);
        })
    });
    it("should update balances after transfer",async function(){
        const initalownerbalance=await hardhatToken.balancesOf(owner.address);
        await hardhatToken.transer(add1.address,14);
        await hardhatToken.transer(add2.address,15);

        const finalownerbalance= await hardhatToken.balancesOf(owner.address);
        expect(finalownerbalance).to.equal(initalownerbalance-29);

        const add1balance= await hardhatToken.balancesOf(add1.address);
        expect(add1balance).to.equal(14);
        const add2balance= await hardhatToken.balancesOf(add2.address);
        expect(add2balance).to.equal(15);
    })
});
})