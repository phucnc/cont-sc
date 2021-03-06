// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SimpleExchangeNFT is Ownable, ReentrancyGuard {
    enum CirculatingToken { BNB, BUSD, CONT }

    struct NftPrice {
        uint256 price;
        CirculatingToken token;
    }

    event SellToken ( uint256 indexed tokenId, uint256 indexed price, CirculatingToken indexed token );
    event BuyToken ( uint256 indexed tokenId, uint256 indexed price, CirculatingToken indexed token );

    // Mapping from NFT ID to NFT price
    mapping (uint256 => NftPrice) public nftSellPrices; 

    ERC721 public nftAddress;
    IERC20 public busdAddress;
    IERC20 public contAddress;

    constructor (address _nftAddress, address _busdAddress, address _contAddress) {
        require(_nftAddress != address(0), "SimpleExchangeNFT: nftAddress is the zero address");
        require(_busdAddress != address(0), "SimpleExchangeNFT: busdAddress is the zero address");

        nftAddress = ERC721(_nftAddress);
        busdAddress = ERC20(_busdAddress);
        contAddress = ERC20(_contAddress);
    }

    function sellToken(uint256 tokenId, NftPrice memory nftPrice) public {
        require(msg.sender != address(0) && msg.sender != address(this), "SimpleExchangeNFT: sender is the zero address");
        require(nftAddress.ownerOf(tokenId) == msg.sender, "SimpleExchangeNFT: sender is not owner ");
        require(nftPrice.price > 0, "SimpleExchangeNFT: NFT price must then ZERO");

        NftPrice memory nftPriceExisted = nftSellPrices[tokenId];
        require(nftPriceExisted.price == 0, "SimpleExchangeNFT: NFT is selling");

        nftSellPrices[tokenId] = nftPrice;

        emit SellToken(tokenId, nftPrice.price, nftPrice.token);
    }

    function buyToken(uint256 tokenId) payable public nonReentrant {
        require(msg.sender != address(0) && msg.sender != address(this), "SimpleExchangeNFT: sender is the zero address");

        NftPrice memory nftPrice = nftSellPrices[tokenId];
        require(nftPrice.price > 0, "SimpleExchangeNFT: NFT not for sell");

        address addressSeller = nftAddress.ownerOf(tokenId);

        if (nftPrice.token == CirculatingToken.BUSD) {
            require(busdAddress.balanceOf(msg.sender) >= nftPrice.price, "SimpleExchangeNFT: BUSD amount is less than price");

            busdAddress.transferFrom(msg.sender, addressSeller, nftPrice.price);
        } else if (nftPrice.token == CirculatingToken.CONT) {
            require(contAddress.balanceOf(msg.sender) >= nftPrice.price, "SimpleExchangeNFT: CONT amount is less than price");

            contAddress.transferFrom(msg.sender, addressSeller, nftPrice.price);
        } else if (nftPrice.token == CirculatingToken.BNB) {
            require(msg.value >= nftPrice.price, "SimpleExchangeNFT: BNB amount is less than price");

            payable(addressSeller).transfer(msg.value);
        } else {
            require(false, "SimpleExchangeNFT: token is not support");
        }

        nftAddress.safeTransferFrom(addressSeller, msg.sender, tokenId);
        delete nftSellPrices[tokenId];

        emit BuyToken(tokenId, nftPrice.price, nftPrice.token);
    }
}