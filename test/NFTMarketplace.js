const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTMarketplace", function () {
  let contract;
  let owner;
  let seller;
  let buyer;
  let tokenId;
  let listPrice;
  const tokenURI = "https://tokenURI.com";
  const price = ethers.utils.parseEther("0.1"); // 0.1 ETH

  beforeEach(async function () {
    [owner, seller, buyer] = await ethers.getSigners();

    const NFTMarketplace = await ethers.getContractFactory("NFTMarketplace");

    contract = await NFTMarketplace.connect(owner).deploy();

    await contract.deployed();

    listPrice = await contract.getListPrice();
  });

  it("should allow owner to update list price", async function () {
    const newListPrice = ethers.utils.parseEther("0.05");

    await contract.connect(owner).updateListPrice(newListPrice);
    expect(await contract.getListPrice()).to.equal(newListPrice);
  });

  it("should create a token and list it in the marketplace", async function () {
    await contract.connect(seller).createToken(tokenURI, price, {value: listPrice});

    tokenId = await contract.getCurrentToken();

    const listedToken = await contract.getListedTokenForId(tokenId);
    expect(listedToken.owner).to.equal(contract.address);
    expect(listedToken.seller).to.equal(seller.address);
    expect(listedToken.price).to.equal(price);
    expect(listedToken.sold).to.equal(false);
  });

  it("should allow buyer to purchase a token", async function () {
    await contract.connect(seller).createToken(tokenURI, price, {value: listPrice});

    tokenId = await contract.getCurrentToken();

    await contract.connect(buyer).executeSale(tokenId, { value: price });

    const ownerOfToken = await contract.getOwnerOfToken(tokenId);
    expect(ownerOfToken).to.equal(buyer.address);

    const listedToken = await contract.getListedTokenForId(tokenId);
    expect(listedToken.owner).to.equal(buyer.address);
    expect(listedToken.price).to.equal(price);
    expect(listedToken.sold).to.equal(true);

    const itemsSold = await contract.getItemSold();
    expect(itemsSold).to.equal(1);
  });

  it("should allow seller to resell a token", async function () {
    await contract.connect(seller).createToken(tokenURI, price, {value: listPrice});

    tokenId = await contract.getCurrentToken();

    await contract.connect(buyer).executeSale(tokenId, { value: price });

    await contract.connect(buyer).resellToken(tokenId, price, {value: listPrice});

    const ownerOfToken = await contract.getOwnerOfToken(tokenId);
    expect(ownerOfToken).to.equal(contract.address);

    const listedToken = await contract.getListedTokenForId(tokenId);
    expect(listedToken.owner).to.equal(contract.address);
    expect(listedToken.seller).to.equal(buyer.address);
    expect(listedToken.price).to.equal(price);
    expect(listedToken.sold).to.equal(false);

    const itemsSold = await contract.getItemSold();
    expect(itemsSold).to.equal(0);
  });
});