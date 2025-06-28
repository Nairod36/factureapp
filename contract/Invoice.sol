// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Invoice
 * @dev Smart contract simple pour enregistrer et régler des factures USDC (ERC20)
 */
interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract Invoice {
    struct Facture {
        address marchand;
        address client;
        uint256 montant;
        bool payee;
    }
    
    IERC20 public usdc;
    uint256 public compteur;
    mapping(uint256 => Facture) public factures;

    event FactureCreee(uint256 id, address marchand, address client, uint256 montant);
    event FacturePayee(uint256 id, address client);

    constructor(address usdcAddress) {
        usdc = IERC20(usdcAddress);
    }

    function creerFacture(address client, uint256 montant) external returns (uint256) {
        compteur++;
        factures[compteur] = Facture(msg.sender, client, montant, false);
        emit FactureCreee(compteur, msg.sender, client, montant);
        return compteur;
    }

    function payerFacture(uint256 id) external {
        Facture storage f = factures[id];
        require(!f.payee, "Deja payee");
        require(msg.sender == f.client, "Seul le client peut payer");
        require(usdc.transferFrom(msg.sender, f.marchand, f.montant), "Paiement USDC echoue");
        f.payee = true;
        emit FacturePayee(id, msg.sender);
    }

    function estPayee(uint256 id) external view returns (bool) {
        return factures[id].payee;
    }
}
