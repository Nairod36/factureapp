// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Invoice
 * @dev Smart contract pour enregistrer et régler des factures USDC
 * @author Votre nom
 */
interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract Invoice {
    struct Facture {
        address marchand;
        address client;
        uint256 montant;
        bool payee;
        uint256 dateCreation;
        string description;
    }
    
    IERC20 public immutable usdc;
    uint256 public compteur;
    mapping(uint256 => Facture) public factures;
    mapping(address => uint256[]) public facturesMarchand;
    mapping(address => uint256[]) public facturesClient;

    event FactureCreee(uint256 indexed id, address indexed marchand, address indexed client, uint256 montant, string description);
    event FacturePayee(uint256 indexed id, address indexed client, uint256 montant);

    modifier factureExiste(uint256 id) {
        require(id > 0 && id <= compteur, "Facture inexistante");
        _;
    }

    constructor(address usdcAddress) {
        require(usdcAddress != address(0), "Adresse USDC invalide");
        usdc = IERC20(usdcAddress);
    }

    function creerFacture(address client, uint256 montant, string calldata description) external returns (uint256) {
        require(client != address(0), "Adresse client invalide");
        require(montant > 0, "Montant doit etre superieur a 0");
        require(client != msg.sender, "Le client ne peut pas etre le marchand");
        
        compteur++;
        factures[compteur] = Facture({
            marchand: msg.sender,
            client: client,
            montant: montant,
            payee: false,
            dateCreation: block.timestamp,
            description: description
        });
        
        facturesMarchand[msg.sender].push(compteur);
        facturesClient[client].push(compteur);
        
        emit FactureCreee(compteur, msg.sender, client, montant, description);
        return compteur;
    }

    function payerFacture(uint256 id) external factureExiste(id) {
        Facture storage f = factures[id];
        require(!f.payee, "Facture deja payee");
        require(msg.sender == f.client, "Seul le client peut payer");
        
        // Vérifier l'allowance et le solde
        require(usdc.allowance(msg.sender, address(this)) >= f.montant, "Allowance USDC insuffisante");
        require(usdc.balanceOf(msg.sender) >= f.montant, "Solde USDC insuffisant");
        
        // Effectuer le transfert
        require(usdc.transferFrom(msg.sender, f.marchand, f.montant), "Transfert USDC echoue");
        
        f.payee = true;
        emit FacturePayee(id, msg.sender, f.montant);
    }

    function estPayee(uint256 id) external view factureExiste(id) returns (bool) {
        return factures[id].payee;
    }
    
    function getFacture(uint256 id) external view factureExiste(id) returns (Facture memory) {
        return factures[id];
    }
    
    function getFacturesMarchand(address marchand) external view returns (uint256[] memory) {
        return facturesMarchand[marchand];
    }
    
    function getFacturesClient(address client) external view returns (uint256[] memory) {
        return facturesClient[client];
    }
    
    function getNombreFactures() external view returns (uint256) {
        return compteur;
    }
}
