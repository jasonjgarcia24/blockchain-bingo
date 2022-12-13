// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

interface IBingoCardDeck is IERC721, IAccessControl {
    event WinnerClaimed(
        address indexed winner,
        uint256 tokenId,
        bytes13 winningResults
    );

    function setEntryFee(uint256 _entryFee) external;

    function recordValue(uint256 _value) external;

    function withdrawWinnings() external;

    function mint(address _player, uint256 _cardGenerator) external payable;

    function claimWinner() external;
}
