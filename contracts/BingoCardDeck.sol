// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "hardhat/console.sol";

contract BingoCardDeck is ERC721, AccessControl, Pausable {
    event PlayerAdded(
        address indexed player,
        uint256 indexed tokenId,
        uint256 entryFee
    );

    event WinnerClaimed(
        address indexed winner,
        uint256 tokenId,
        bytes13 winningResults
    );

    uint256 tokenId;
    uint256 public entryFee;

    bytes32 private constant _ADMIN_ROLE_ = "ADMIN";
    bytes32 private constant _PLAYER_ROLE_ = "PLAYER";
    bytes32 private constant _WINNER_ROLE_ = "WINNER";

    // Each space (1-5)   in the 'B' column contains a number from 1 - 15.
    // Each space (6-10)  in the 'I' column contains a number from 16 - 30.
    // Each space (11-15) in the 'N' column contains a number from 31 - 45.
    // Each space (16-20) in the 'G' column contains a number from 46 - 60.
    // Each space (21-25) in the 'O' column contains a number from 61 - 75.
    uint256 public round;
    address public winner;
    mapping(uint256 => bool) public record;
    mapping(address => uint256) public tokens;
    mapping(uint256 => uint256[25]) public bingoCards;
    mapping(uint256 => bytes13) public bingoCardsStatus;

    bytes13[13] public winningCombos = [
        bytes13(bytes3(0x111110)),
        bytes13(bytes3(0x111110)) >> ((2 * 8) + 4),
        bytes13(bytes3(0x111110)) >> ((5 * 8)),
        bytes13(bytes3(0x111110)) >> ((7 * 8) + 4),
        bytes13(bytes3(0x111110)) >> ((10 * 8)),
        bytes13(0x10000100001000010000100000),
        bytes13(0x10000100001000010000100000) >> 4,
        bytes13(0x10000100001000010000100000) >> 8,
        bytes13(0x10000100001000010000100000) >> 12,
        bytes13(0x10000100001000010000100000) >> 16,
        bytes13(0x10000010000010000010000010),
        bytes13(0x00001000100010001000100000),
        bytes13(0x10001000000000000000100010)
    ];

    constructor(uint256 _entryFee)
        ERC721("MetaStreet Bingo Challenge", "MSBC")
    {
        address _bingoCardAdmin = _msgSender();

        _setRoleAdmin(_ADMIN_ROLE_, _ADMIN_ROLE_);
        _setRoleAdmin(_PLAYER_ROLE_, _PLAYER_ROLE_);

        _setupRole(_ADMIN_ROLE_, _bingoCardAdmin);
        _setupRole(_PLAYER_ROLE_, _bingoCardAdmin);

        entryFee = _entryFee;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setEntryFee(uint256 _entryFee) external onlyRole(_ADMIN_ROLE_) {
        entryFee = _entryFee;
    }

    function recordValue(uint256 _value)
        external
        onlyRole(_ADMIN_ROLE_)
        whenNotPaused
    {
        record[_value] = true;
    }

    function withdrawWinnings() external onlyRole(_WINNER_ROLE_) whenPaused {
        payable(msg.sender).transfer(address(this).balance);
    }

    function mint(address _player, uint256 _cardGenerator)
        external
        payable
        whenNotPaused
    {
        require(msg.value >= entryFee, "Insufficient entry fee");

        tokenId += 1;

        _initBingoCard(tokenId, _cardGenerator);
        bingoCardsStatus[tokenId] = bytes13(bytes1(0x01)) >> ((5 * 8) + 4);

        _safeMint(_player, tokenId);

        emit PlayerAdded(_msgSender(), tokenId, entryFee);
    }

    function _initBingoCard(uint256 _tokenId, uint256 _cardGenerator)
        internal
        whenNotPaused
    {
        _cardGenerator = _cardGenerator % 10**50;

        uint256[5] memory _temp;
        uint256 _val;

        for (uint256 k; k < 25; k++) {
            // Reset _temp for ever five (i.e. column).
            _temp = k % 5 == 0 ? [uint256(0), 0, 0, 0, 0] : _temp;

            // Use two bytes to find random value.
            _val = ((_cardGenerator - (_cardGenerator % 10)) / 10) % 10;
            _val = _cardGenerator % 10 > 4 ? _val : 15 - _val;
            _val += (15 * (k / 5));

            uint256 _step = 1;
            while (_temp[k % 5] == 0) {
                if (
                    _val != _temp[0] &&
                    _val != _temp[1] &&
                    _val != _temp[2] &&
                    _val != _temp[3] &&
                    _val != _temp[4]
                ) {
                    _temp[k % 5] = _val;
                }
                // Add incremented _step and push away from duplicate
                // if _val exists in _temp.
                _step += 1;
                _val += (_val % 7) + _step;

                // Check for row overflow
                _val = _val < 15 + (15 * (k / 5)) ? _val : 0 + (15 * (k / 5));
            }

            bingoCards[_tokenId][k] = _temp[k % 5];
            console.logUint(bingoCards[_tokenId][k]);

            _cardGenerator = (_cardGenerator - (_cardGenerator % 100)) / 100;
        }
    }

    function claimWinner() external onlyRole(_PLAYER_ROLE_) {
        _checkWinner(_msgSender());
    }

    function _checkWinner(address _player) internal {
        bytes13 _notRecorded = bytes13(bytes1(0x00));
        bytes13 _bingoCardSlot;
        bool _isRecorded;
        uint256 _tokenId = tokens[_player];
        uint256 k;

        while (k < 25) {
            _bingoCardSlot = (bytes13(bytes1(0x10)) >> (4 * k));
            _isRecorded =
                bingoCardsStatus[_tokenId] & _bingoCardSlot != _notRecorded;

            if (_isRecorded) {
                k += 1;
                continue;
            }

            uint256 _bingoCardVal = bingoCards[_tokenId][k];

            if (record[_bingoCardVal]) {
                bingoCardsStatus[_tokenId] |= _bingoCardSlot;
            }

            k += 1;
        }

        k = 0;
        while (k < 13 && winner != _player) {
            winner = winningCombos[k] & bingoCardsStatus[_tokenId] ==
                winningCombos[k]
                ? _player
                : winner;

            k += 1;
        }

        if (winner == _player) {
            _pause();
            _setupRole(_WINNER_ROLE_, _player);

            emit WinnerClaimed(_player, _tokenId, bingoCardsStatus[_tokenId]);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256,
        uint256
    ) internal override {
        uint256 _receiverTokenId = tokens[to];

        // require(
        //     bingoCardsStatus[_receiverTokenId] == bytes13(bytes1(0x00)),
        //     "Cannot play more than one card"
        // );

        super._beforeTokenTransfer(from, to, 0, 0);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256,
        uint256
    ) internal override {
        tokens[from] = 0;
        tokens[to] = tokenId;

        if (from != address(0)) {
            renounceRole(_PLAYER_ROLE_, from);
        }

        if (to != address(0)) {
            grantRole(_PLAYER_ROLE_, to);
        }

        if (from != address(0) && winner == from) {
            winner = to;

            renounceRole(_WINNER_ROLE_, from);
            grantRole(_WINNER_ROLE_, to);
        }
    }
}
