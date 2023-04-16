/* pages/_app.js */
import '../styles/globals.css'
import Link from 'next/link'

function MyApp({ Component, pageProps }) {
  return (
    <div>
      <nav className="border-b p-6 md:flex">
        <p className="text-4xl font-bold mx-auto">NFTs MarketPlace</p>
        <div className="flex mt-4">
          <Link href="/" legacyBehavior>
            <p className="mr-6 font-medium text-purple-700 hover:cursor-pointer hover:text-purple-600">
              Home
            </p>
          </Link>
          <Link href="/create-nft">
            <button className="mr-6 font-medium text-purple-700 hover:cursor-pointer hover:text-purple-600">
              List NFTs
            </button>
          </Link>
          <Link href="/my-nfts">
            <p className="mr-6 font-medium text-purple-700 hover:cursor-pointer hover:text-purple-600">
              My NFTs
            </p>
          </Link>
          <Link href="/dashboard">
            <p className="mr-6 font-medium text-purple-700 hover:cursor-pointer hover:text-purple-600">
              Dashboard
            </p>
          </Link>
        </div>
      </nav>
      <Component {...pageProps} />
    </div>
  );
}

export default MyApp