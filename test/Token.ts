import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { ethers } from "hardhat"
import { CustomToken, CustomToken__factory } from "../typechain"
import { expandTo18Decimals } from "./utilities/utilities"

describe("Custom Token Test",()=>{

    let owner : SignerWithAddress
    let signers : SignerWithAddress[]
    let token : CustomToken

    beforeEach(async()=>{
        signers = await ethers.getSigners();
        owner = signers[0];
        token = await new CustomToken__factory(owner).deploy("Custom","CSM",signers[8].address,signers[9].address,signers[10].address);
    })

    it("Testing Token", async()=>{
        console.log("totalSupply:",await token.totalSupply());
        await token.connect(owner).transfer(signers[1].address,expandTo18Decimals(1));
        console.log("totalSupply:",await token.totalSupply());
        console.log("Balance for the owner: ", await token.balanceOf(signers[1].address));
    })
})