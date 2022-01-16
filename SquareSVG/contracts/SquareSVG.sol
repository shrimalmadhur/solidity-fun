//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import 'base64-sol/base64.sol';
import './UintStrings.sol';

contract SquareSVG is ERC721URIStorage {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint128 private _startMintFeeWei = 1e17;
    
    address public manager;

    mapping(uint256 => address)  public tokenMapping;

    constructor(address _manager) ERC721("SquareSVG Project", "SSVG") {
        manager = _manager;
    }

    function mintFeeWei() public view returns(uint256){
        return _startMintFeeWei + (64 * 1e16);
    }

    function mint(address _to) payable external {
        require(msg.value >= mintFeeWei(), "SquareSVG: Mint fee too low");
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(_to, newItemId);
        _setTokenURI(newItemId, tokenURI(newItemId));
        tokenMapping[newItemId] = _to;
    }

    function tokenURI(uint256 tokenId) public override pure returns(string memory) {
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"Square SVG',
                                ' #',
                                UintStrings.decimalString(tokenId, 0, false),
                                '", "description":"',
                                'Square SVG is a test project. No use',
                                '", "image": "',
                                'data:image/svg+xml;base64,',
                                Base64.encode(bytes(generateSVG(tokenId))),
                                '"}'
                            )
                        )
                    )
            )
        );
    }

    function generateSVG(uint256 tokenId) private pure returns (string memory) {
        return string(
            abi.encodePacked(
                '<svg version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" viewBox="0 0 200 200" width="200" height="200" xml:space="preserve">',
                '<style type="text/css">',
                    'rect{width:50px;height:50px;}',
                '</style>',
                generateRects(tokenId),
                '</svg>'
            )
        );
    }

    function generateRects(uint256 tokenId) private pure returns (string memory result) {
        (string memory r, string memory g, string memory b, string memory a) = rgba(tokenId);
        for (uint i; i < 4; i++) {
            for (uint j; j < 4; j++) {
                result = string(abi.encodePacked(result, generateRect(i*j, r, g, b, a)));
            }
        }
    }

    function generateRect(uint256 index, string memory r, string memory g, string memory b, string memory a) private pure returns (string memory) {
        return string(
            abi.encodePacked(
            '<rect x="',
            UintStrings.decimalString((index % 4) * 50, 0, false),
            '" y="',
            UintStrings.decimalString((index / 4) * 50, 0, false),
            '" fill="rgba(',
            r,
            ',',
            g,
            ',',
            b,
            ',',
            a,
            ')"/>'
            )
        );
    }

    function rgba(uint256 index) public pure returns (string memory, string memory, string memory, string memory){
        bytes32 h = keccak256(abi.encodePacked(index));
        string memory r = UintStrings.decimalString(uint8(h[0]), 0, false);
        string memory g = UintStrings.decimalString(uint8(h[1]), 0, false);
        string memory b = UintStrings.decimalString(uint8(h[2]), 0, false);
        string memory a = UintStrings.decimalString(uint8(h[3]), 2, false);

        return (r,g,b,a);
    }

    function updateManager(address _manager) external {
        require(msg.sender == manager, "SquareSVG: forbidden");
        manager = _manager;
    }

    function payManager(uint256 amount) external {
        require(msg.sender == manager, "SquareSVG: forbidden");
        require(amount <= address(this).balance, "SquareSVG:  amount  too high");
        payable(manager).transfer(amount);
    }
}

