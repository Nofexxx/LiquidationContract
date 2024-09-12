// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

/* ====== EXTERNAL IMPORTS ====== */

/* ====== INTERFACES IMPORTS ====== */

/* ====== CONTRACTS IMPORTS ====== */

contract Template {
    /* ======== STATE ======== */

    uint256 public number;

    /* ======== ERRORS ======== */

    /* ======== EVENTS ======== */

    /* ======== CONSTRUCTOR AND INIT ======== */

    /* ======== EXTERNAL/PUBLIC ======== */

    function setNumber(uint256 newNumber) external {
        number = newNumber;
    }

    function increment() external {
        number++;
    }

    /* ======== INTERNAL ======== */

    /* ======== ADMIN ======== */

    /* ======== VIEW ======== */
}
