// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ConstructionPlatform {
    // Constructeur (owner du contrat)
    address public constructeur;
    
    // Événements
    event ProjetAjoute(uint256 id, string nom, uint256 prix);
    event PaiementEffectue(uint256 projetId, address client, uint256 montant);
    event ProjetComplete(uint256 projetId);
    event RetraitFonds(address destinataire, uint256 montant);
    
    // Structure de données pour un projet immobilier
    struct Projet {
        string nom;
        string description;
        uint256 prix;
        uint256 montantCollecte;
        bool estComplete;
        address[] clients;
    }
    
    // Mapping des projets par ID
    mapping(uint256 => Projet) public projets;
    
    // Compteur pour les IDs de projets
    uint256 public nextProjetId = 1;
    
    // Modificateur pour restreindre l'accès au constructeur
    modifier seulementConstructeur() {
        require(msg.sender == constructeur, "Seul le constructeur peut effectuer cette action");
        _;
    }
    
    // Constructeur du contrat
    constructor() {
        constructeur = msg.sender;
    }
    
    // Fonction pour ajouter un nouveau projet (externe, seulement constructeur)
    function ajouterProjet(
        string memory _nom,
        string memory _description,
        uint256 _prix
    ) external seulementConstructeur {
        require(_prix > 0, "Le prix doit etre superieur a zero");
        
        projets[nextProjetId] = Projet({
            nom: _nom,
            description: _description,
            prix: _prix,
            montantCollecte: 0,
            estComplete: false,
            clients: new address[](0)
        });
        
        emit ProjetAjoute(nextProjetId, _nom, _prix);
        nextProjetId++;
    }
    
    // Fonction pour investir dans un projet (payable, publique)
    function investirDansProjet(uint256 _projetId) external payable {
        require(_projetId > 0 && _projetId < nextProjetId, "Projet invalide");
        Projet storage projet = projets[_projetId];
        
        require(!projet.estComplete, "Projet deja complete");
        require(msg.value > 0, "Montant doit etre superieur a zero");
        require(projet.montantCollecte + msg.value <= projet.prix, "Montant total depasse le prix du projet");
        
        projet.montantCollecte += msg.value;
        projet.clients.push(msg.sender);
        
        emit PaiementEffectue(_projetId, msg.sender, msg.value);
    }
    
    // Fonction pour marquer un projet comme complet (interne, seulement constructeur)
    function completerProjet(uint256 _projetId) external seulementConstructeur {
        Projet storage projet = projets[_projetId];
        
        assert(projet.montantCollecte >= projet.prix); // Ne devrait jamais arriver si les autres vérifications sont en place
        require(!projet.estComplete, "Projet deja complete");
        
        projet.estComplete = true;
        emit ProjetComplete(_projetId);
    }
    
    // Fonction pour retirer les fonds collectés (seulement constructeur)
    function retirerFonds() external seulementConstructeur {
        uint256 balance = address(this).balance;
        require(balance > 0, "Aucun fonds a retirer");
        
        (bool success, ) = constructeur.call{value: balance}("");
        require(success, "Transfert echoue");
        
        emit RetraitFonds(constructeur, balance);
    }
    
    // Fonction view pour obtenir les détails d'un projet
    function getDetailsProjet(uint256 _projetId) external view returns (
        string memory nom,
        string memory description,
        uint256 prix,
        uint256 montantCollecte,
        bool estComplete,
        uint256 nombreClients
    ) {
        require(_projetId > 0 && _projetId < nextProjetId, "Projet invalide");
        Projet storage projet = projets[_projetId];
        
        return (
            projet.nom,
            projet.description,
            projet.prix,
            projet.montantCollecte,
            projet.estComplete,
            projet.clients.length
        );
    }
    
    // Fonction pure pour calculer le pourcentage de complétion
    function calculerPourcentageCompletion(uint256 _projetId) external view returns (uint256) {
        require(_projetId > 0 && _projetId < nextProjetId, "Projet invalide");
        Projet storage projet = projets[_projetId];
        
        return (projet.montantCollecte * 100) / projet.prix;
    }
    
    // Fonction d'urgence en cas de problème (seulement constructeur)
    function emergencyStop() view external seulementConstructeur {
        revert("Fonctionnalite d'urgence activee");
    }
}