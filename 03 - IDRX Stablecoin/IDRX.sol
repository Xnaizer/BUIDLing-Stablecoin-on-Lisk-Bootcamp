// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract IDRX is ERC20, Ownable, ERC20Permit {
    constructor(address recipient, address initialOwner)
        ERC20("IDRX", "IDRX")
        Ownable(initialOwner)
        ERC20Permit("IDRX")
    {
        _mint(recipient, 100000 * 10 ** 2); // 100,000.00 IDRX
    }

    function decimals() public view virtual override returns (uint8) {
        return 2; // Hanya dua desimal
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
