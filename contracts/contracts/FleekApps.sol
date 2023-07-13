// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./util/FleekSVG.sol";
import "./util/NonBlockingLzApp.sol";
import "./FleekERC721.sol";

contract FleekApps is Initializable, ERC721Upgradeable, NonblockingLzApp {
    using Strings for address;
    using Base64 for bytes;

    /**
     * The metadata that is stored for each build.
     */
    struct Build {
        string commitHash;
        string gitRepository;
        string ipfsHash;
        string domain;
    }

    /**
     * The properties are stored as string to keep consistency with
     * other token contracts, we might consider changing for bytes32
     * in the future due to gas optimization.
     */
    struct Token {
        string name; // Name of the site
        string image; // Image
        string ipfsHash; // IPFS Hash
    }

    uint256 public bindCount;
    mapping(uint256 => Token) public bindings;

    // FleekERC721 main;
    address public main;
    
    uint16 destChainId = 10121; // goerli
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory _name, string memory _symbol, address mainCollection, address _lzEndpoint) public initializer {
        __ERC721_init(_name, _symbol);
        main = mainCollection;
        trustedRemoteLookup[destChainId] = abi.encodePacked(mainCollection, address(this));
        NonblockingLzApp.initializeNonblockingLzApp(_lzEndpoint);
    }

    // modifier _requireMainMinted(uint256 _tokenId) {
    //     require(main.ownerOf(_tokenId) != address(0), "Main token does not exist");
    //     _;
    // }

    function mint(address _to, uint256 _tokenId) public /**_requireMainMinted(_tokenId)*/ payable {
        _mint(_to, bindCount);
        // Call the main erc contract to add the metadata in this contract
        _lzSend(uint16(destChainId), abi.encode(_tokenId), payable(msg.sender), address(0x0), bytes(""), msg.value);
    }

    function _nonblockingLzReceive(uint16, bytes memory, uint64, bytes memory _payload) override internal {
        (string memory name, string memory ens, string memory logo, string memory color, string memory ipfsHash) = abi.decode(_payload, (string, string, string, string, string));
        bindings[bindCount] = Token (
            name,
            FleekSVG.generateBase64(name, ens, logo, color),
            ipfsHash
        );
        bindCount++;
    }

    function tokenURI(uint256 _bindId) public view virtual override(ERC721Upgradeable) returns (string memory) {
        Token memory token = bindings[_bindId];
        // prettier-ignore
        return string(abi.encodePacked(_baseURI(),
            abi.encodePacked('{',
                '"owner":"', ownerOf(_bindId).toHexString(), '",',
                '"name":"', token.name, '",',
                '"image":"', token.image, '",',
                '"external_url":"ipfs://', token.ipfsHash, '"',
            '}').encode()
        ));
    }

    /**
     * @dev Override of transfer of ERC721.
     * Transfer is disabled for NFA tokens.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual override {
        revert TransferIsDisabled();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "data:application/json;base64,";
    }
}
