import { ethers } from 'ethers'
import { useEffect, useRef, useState } from 'react'
import axios from 'axios'
import Web3Modal from 'web3modal'
import { marketplaceAddress } from "../../.config.js";
import NFTMarketplace from '../../artifacts/contracts/NFTMarket.sol/NFTMarketplace.json';

export default function Home() {
  const web3ModalRef = useRef();
  const [nfts, setNfts] = useState([]);
  const [walletConnected, setWalletConnected] = useState(false);
  const [loading, setLoading] = useState(false);
  const [waiting, setWaiting] = useState(false);

  useEffect(() => {
    if (!walletConnected) {
      web3ModalRef.current = new Web3Modal({
        network: "mumbai",
        providerOptions: {},
        disableInjectedProvider: false,
      });
    }
    connectWallet();

    loadNFTs()
  }, [walletConnected]);

  async function connectWallet() {
    try {
      await getProviderOrSigner();
      setWalletConnected(true);      
    } catch (error) {
      console.log(error);
    }
  }

  async function getProviderOrSigner (needSigner = false) {
    const connection = await web3ModalRef.current.connect();
    const provider = new ethers.providers.Web3Provider(connection);

    const { chainId } = await provider.getNetwork();
    if (chainId !== 80001) {
      window.alert("Change the network to Mumbai");
      throw new Error("Change network to Mumbai");
    }

    if (needSigner) {
      const signer = provider.getSigner();
      return signer;
    }
    return provider;
  };

  async function loadNFTs() {

    const provider = await getProviderOrSigner();
    const contract = new ethers.Contract(marketplaceAddress, NFTMarketplace.abi, provider);
    const NFTs = await contract.fetchMarketNFTs();

    /*
    *  map over items returned from smart contract and format 
    *  them as well as fetch their token metadata
    */
    const items = await Promise.all(NFTs.map(async nft => {
      const tokenURl = await contract.tokenURI(nft.tokenId);

      const metaData = await axios.get(tokenURl);

      let price = ethers.utils.formatUnits(nft.price.toString(), 'ether');

      let item = {
        price,
        tokenId: nft.tokenId.toNumber(),
        seller: nft.seller,
        owner: nft.owner,
        image: metaData.data.image,
        name: metaData.data.name,
        description: meta.data.description,
      }

      return item
    }));
    setLoading(true);
    setNfts(items);
    setLoading(false);
  }
  
  async function buyNft(nft) {
    /* needs the user to sign the transaction, so will use Web3Provider and sign it */
    const signer = await getProviderOrSigner(true);
    const contract = new ethers.Contract(marketplaceAddress, NFTMarketplace.abi, signer)

    /* user will be prompted to pay the asking proces to complete the transaction */
    const price = ethers.utils.parseUnits(nft.price.toString(), 'ether')   
    const transaction = await contract.executeSale(nft.tokenId, {
      value: price
    })
    setWaiting(true);
    await transaction.wait()

    setWaiting(false);
    loadNFTs()
  }

  if (loading && !nfts.length) return (<h1 className="px-20 py-10 text-3xl">No items in marketplace</h1>);

  if (waiting) return (<h1 className="px-20 py-10 text-3xl">Transaction in progress</h1>);

  return (
    <div className="flex justify-center">
      <div className="px-4" style={{ maxWidth: '1600px' }}>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 pt-4">
          {
            nfts.map((nft, i) => (
              <div key={i} className="border shadow rounded-xl overflow-hidden">
                <img src={nft.image} />
                <div className="p-4">
                  <p style={{ height: '64px' }} className="text-2xl font-semibold">{nft.name}</p>
                  <div style={{ height: '70px', overflow: 'hidden' }}>
                    <p className="text-gray-400">{nft.description}</p>
                  </div>
                </div>
                <div className="p-4 bg-black">
                  <p className="text-2xl font-bold text-white">{nft.price} ETH</p>
                  <button className="mt-4 w-full bg-purple-500 text-white font-bold py-2 px-12 rounded" onClick={() => buyNft(nft)}>Buy</button>
                </div>
              </div>
            ))
          }
        </div>
      </div>
    </div>
  )
}