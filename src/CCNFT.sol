// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {console} from "../lib/forge-std/src/console.sol";
import {IERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {ERC721} from  "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Counters} from "../lib/openzeppelin-contracts/contracts/utils/Counters.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";


contract CCNFT is  ERC721Enumerable, Ownable, ReentrancyGuard {

//EVENTOS
// indexed: Permiten realizar búsquedas en los registros de eventos.

// Compra NFTs
    event Buy(address indexed buyer, uint256 indexed tokenId, uint256 value); 
// buyer: La dirección del comprador.
// tokenId: El ID único del NFT comprado.
// value: El valor asociado al NFT comprado.

// Reclamamo NFTs.
    event Claim(address indexed claimer, uint indexed tokenId);
// claimer: La dirección del usuario que reclama los NFTs.
// tokenId: El ID único del NFT reclamado.

// Transferencia de NFT de un usuario a otro.
    event Trade(address indexed buyer,address indexed seller,uint indexed tokenId,uint value);
// buyer: La dirección del comprador del NFT.
// seller: La dirección del vendedor del NFT.
// tokenId: El ID único del NFT que se transfiere.
// value: El valor pagado por el comprador al vendedor por el NFT (No indexed).

// Venta de un NFT.
    event PutOnSale(uint indexed tokenId,uint price);
// tokenId: El ID único del NFT que se pone en venta.
// price: El precio al cual se pone en venta el NFT (No indexed).

// Retira de NFT de la lista de venta.
    event RemoveFromSale(uint256 indexed tokenId);
// tokenId: El ID único del NFT que se retira de la venta.

// Estructura del estado de venta de un NFT.
    struct TokenSale {
       bool onSale; // Indicamos si el NFT está en venta.
       uint256 price; // Indicamos el precio del NFT si está en venta.
    }

// Biblioteca Counters de OpenZeppelin para manejar contadores de manera segura.
    using Counters for Counters.Counter; 


//NFT TOKEN ID
// Contador para asignar IDs únicos a cada NFT que se crea.
    Counters.Counter private tokenIdTracker;

// Mapeo del ID de un token (NFT) a un valor específico.
    mapping(uint256 => uint256) public values;

// Mapeo de un valor a un booleano para indicar si el valor es válido o no.
    mapping(uint256 => bool) public validValues;

//TOKENID--> TokenSale (bool onSale,uint nftPrice)
// Mapeo del ID de un token (NFT) a su estado de venta (TokenSale).
    mapping(uint256 => TokenSale) public tokensOnSale;

// Lista que contiene los IDs de los NFTs que están actualmente en venta.
    uint256[] public listTokensOnSale;
    
    address public fundsCollector; // Dirección de los fondos de las ventas de los NFTs
    address public feesCollector; // Dirección de las tarifas de transacción (compra y venta de los NFTs)

    bool public canBuy; // Booleano que indica si las compras de NFTs están permitidas.
    bool public canClaim; // Booleano que indica si la reclamación (quitar) de NFTs está permitida.
    bool public canTrade; // Booleano que indica si la transferencia de NFTs está permitida.

    uint256 public totalValue; // Valor total acumulado de todos los NFTs en circulación.
    uint256 public maxValueToRaise; // Valor máximo permitido para recaudar a través de compras de NFTs.

    uint16 public buyFee; // Tarifa aplicada a las compras de NFTs.
    uint16 public tradeFee; // Tarifa aplicada a las transferencias de NFTs.
    
    uint16 public maxBatchCount; // Límite en la cantidad de NFTs por operación (evitar exceder el límite de gas en una transacción).

    uint32 public profitToPay; // Porcentaje adicional a pagar en las reclamaciones.


// Referencia al contrato ERC20 manejador de fondos. 
    IERC20 public fundsToken;

// Constructor (nombre y símbolo del NFT).  
//consultar por seteo inicial de constructor
    constructor() ERC721("Crypto Campo NFT","CCNFT") Ownable() {
         
    }

    // PUBLIC FUNCTIONS

// Funcion de compra de NFTs. 

// Parametro value: El valor de cada NFT que se está comprando.
// Parametro amount: La cantidad de NFTs que se quieren comprar.
    function buy(uint256 value, uint256 amount) external nonReentrant {
        require(canBuy,"Don't Have Buy permission"); // Verificación de permisos de la compra con "canBuy". Incluir un mensaje de falla.
        
// Verificacón de la cantidad de NFTs a comprar sea mayor que 0 y menor o igual al máximo permitido (maxBatchCount). Incluir un mensaje de falla.
        require(amount > 0 && amount <= maxBatchCount,"Amount of NFT token should be bigger than 0 and smaller than max batch");
        require(validValues[value],"Value without permission"); // Verificación del valor especificado para los NFTs según los valores permitidos en validValues. Incluir un mensaje de falla.

// Verificacón del valor total después de la compra (no debe exeder el valor máximo permitido "maxValueToRaise"). Incluir un mensaje de falla.
        require(totalValue + amount*value <= maxValueToRaise,"Max value exeded");

        totalValue += amount*value ; // Incremento del valor total acumulado por el valor de los NFTs comprados.

        for (uint8 i = 1; i <= amount; i++) { // Bucle desde 1 hasta amount (inclusive) para mintear la cantidad especificada de NFTs.
    
            values[tokenIdTracker.current()] = value ;// Asignar el valor del NFT al tokenId actual "current()" en el mapeo values.
            _safeMint(msg.sender, tokenIdTracker.current()); // Minteo de NFT y asignación al msg.sender.
            // Incremento del contador tokenIdTracker (NFT deben tener un tokenId único).        
            emit Buy(_msgSender(), tokenIdTracker.current(), value);// Evento Buy con el comprador, el tokenId y el valor del NFT.
            tokenIdTracker.increment();                  
        }
      // Transfencia de fondos desde el comprador (_msgSender()) al recolector de fondos (fundsCollector) por el valor total de los NFTs comprados. 
         bool succes = fundsToken.transferFrom(_msgSender(), fundsCollector, value * amount); 
         require(succes,"fundsToken transfer fail");
        // Transferencia de tarifas de compra desde el comprador (_msgSender()) al recolector de tarifas (feesCollector).
        // Tarifa = fracción del valor total de la compra (value * amount * buyFee / 10000).
         bool succ = fundsToken.transferFrom(_msgSender(), feesCollector, value * amount * buyFee / 10000);
         require(succ,"Transfer to fees collector failed");
     
    } 


// Funcion de "reclamo" de NFTs

// Parámetros: Lista de IDs de tokens de reclamo (utilizar calldata).Consultar<---------
    function claim(uint256[] calldata listTokenId) external nonReentrant {
        uint totalClaim ;
        uint256 claimValue ;
        require(canClaim, "Cannot claim"); // Verificacón habilitación de "reclamo" (canClaim). Incluir un mensaje de falla.

        require(listTokenId.length > 0 && listTokenId.length < maxBatchCount,"Incorrect quantity of tokens"); // Verificacón de la cantidad de tokens a reclamar (mayor que 0 y menor o igual a maxBatchCount). Incluir un mensaje de falla.
         // Inicializacion de claimValue a 0.
        TokenSale storage tokenSale; // Variable tokenSale.
        
        for (uint i = 0; i < listTokenId.length;i++) { // Bucle para iterar a través de cada token ID en listTokenId.
            
			require(_exists(listTokenId[i]), "Id not found"); // Verificacón listTokenId[i] exista. Incluir un mensaje de falla.

// Verificamos que el llamador de la función (_msgSender()) sea el propietario del token. Si no es así, la transacción falla con el mensaje "Only owner can Claim".
            require(ownerOf(listTokenId[i]) == msg.sender,"Only owner can Claim"); // Verificacón que _msgSender()) sea el propietario del token. Incluir un mensaje de falla.
            claimValue += values[listTokenId[i]];                // Suma de el valor del token al claimValue acumulado.
            values[listTokenId[i]] = 0; // Reseteo del valor del token a 0.

 
            tokenSale = tokensOnSale[listTokenId[i]]; // Acceso a la información de venta del token
            tokenSale.onSale = false  ; // Desactivacion del estado de venta.
            tokenSale.price =   0   ; // Desactivacion del estado de venta.

            removeFromArray(listTokensOnSale,listTokenId[i]); // Remover el token de la lista de tokens en venta.           
            _burn(listTokenId[i]); // Quemar el token, eliminándolo permanentemente de la circulación.
            emit Claim(msg.sender,listTokenId[i]); // Registrar el ID y propietario del token reclamado.
        }
        // Reducir el totalValue acumulado.
        totalValue -= claimValue;
// Calculo del monto total a transferir (claimValue + (claimValue * profitToPay / 10000)).
        totalClaim = claimValue + (claimValue *profitToPay/10000);
        
// Transferir los fondos desde fundsCollector al (_msgSender()).
        require(claimValue > 0,"Don't have value to claim");
        require(fundsToken.balanceOf(fundsCollector) >= totalClaim, "Insufficient balance in fundsCollector");
        uint256 allowance = fundsToken.allowance(msg.sender, address(fundsToken));
        require(allowance >= totalClaim, "Allowance too low");
        bool success = fundsToken.transferFrom(fundsCollector, _msgSender(), totalClaim);
        //bool success = IERC20(fundsCollector).transfer(msg.sender, totalClaim);
        require(success, "Funds transfer failed");
    }   


// Funcion de compra de NFT que esta en venta.
    function trade(uint tokenId) external nonReentrant { // Parámetro: ID del token.
        require(canTrade,"Can't trade this token"); // Verificación del comercio de NFTs (canTrade). Incluir un mensaje de falla.
        require(_exists(tokenId),"Token dont exist"); // Verificación de existencia del tokenId (_exists). Incluir un mensaje de falla.
// Verificamos que el comprador (el que llama a la función) no sea el propietario actual del NFT. Si lo es, la transacción falla con el mensaje "Buyer is the Seller".
        require(ownerOf(tokenId) != msg.sender,"Buyer is the Seller"); // Verificación de propietario actual del NFT no sea el comprador. Incluir un mensaje de falla.

        TokenSale storage tokenSale = tokensOnSale[tokenId]; // Estado de venta del NFT.

// Verifica que el NFT esté actualmente en venta (onSale es true). Si no lo está, la transacción falla con el mensaje "Token not On Sale".
        require(tokenSale.onSale, "Token not On Sale"); // Verificación del estado de venta (onSale). Incluir un mensaje de falla.

// Transferencia del precio de venta del comprador al propietario actual del NFT usando fundsToken.
        address seller = ownerOf(tokenId);
        uint256 allowance = fundsToken.allowance(seller, msg.sender);
        require(allowance >= tokenSale.price, "Allowance too low");
        console.log("buyer allowance ",allowance);
        uint256 balance = fundsToken.balanceOf(msg.sender);
        require(balance >= tokenSale.price, "Balance too low");
        console.log("balance ",balance);
         bool success = fundsToken.transferFrom(msg.sender, seller, tokenSale.price);
         require(success, "Transfer failed");
      
/*
// Transferencia de tarifa de comercio (calculada como un porcentaje del valor del NFT) del comprador al feesCollector.
       if (!success) {
            revert(); // Incluir un mensaje de falla.
        }*/
  
        emit Trade(msg.sender,seller,tokenId,tokenSale.price); // Registro de dirección del comprador, dirección del vendedor, tokenId, y precio de venta.  

        _safeTransfer(ownerOf(tokenId),msg.sender,tokenId,bytes("")); // Transferencia del NFT del propietario actual al comprador.

        tokenSale.onSale =  false ; // NFT no disponible para la venta.
        tokenSale.price =  0 ; // Reseteo del precio de venta del NFT.
        removeFromArray(listTokensOnSale,tokenId); // Remover el tokenId de la lista listTokensOnSale de NFTs.

    }


// Función para poner en venta un NFT.
    function putOnSale(uint tokenId, uint _price) external { // Parámetros: ID y precio del token.
        require(canTrade,"Dont have Trade permission"); // Verificación de operaciones de comercio (canTrade). Incluir un mensaje de falla.

        require(_exists(tokenId),"Token don't exist"); // Verificción de existencia del tokenId mediante "_exists". Incluir un mensaje de falla.

        require(msg.sender == ownerOf(tokenId),"Only owner can put on sale"); // Verificción remitente de la transacción es propietario del token. Incluir un mensaje de falla.


        TokenSale storage tokenSale = tokensOnSale[tokenId]; // Variable de almacenamiento de datos para el token.

        tokenSale.onSale = true; // Indicar que el token está en venta.
        tokenSale.price = _price;              // Indicar precio de venta del token.

        addToArray(listTokensOnSale,tokenId); // Añadir token a la lista.
        
        emit PutOnSale(tokenId, _price); // Notificar que el token ha sido puesto a la venta (token y precio).
    }


// Función de retiro de venta de NFT.
    function removeFromSale(uint256 tokenId) external { // Parámetro: ID del token.
        require(canTrade,"Dont have Trade permission"); // Verificación de permisos de transacciones (canTrade). Incluir un mensaje de falla.
        require(_exists(tokenId),"Token don't exist"); // Verificación de existencia del token. Incluir un mensaje de falla.
        require(msg.sender == ownerOf(tokenId)); // Verificación del _msgSender() es el propietario del token. Incluir un mensaje de falla.
    

        TokenSale storage tokenSale = tokensOnSale[tokenId]; // Recuper estado de venta del token almacenamiento en tokenSale.
		require(tokenSale.onSale); // Verificación de venta del token (tokenSale.onSale). Incluir un mensaje de falla.
        tokenSale.onSale = false           ; // Indicar que el token ya no está en venta.
        tokenSale.price = 0            ; // Restablecer el precio del token.
        removeFromArray(listTokensOnSale,tokenId); // Eliminar el tokenId de la lista.

        emit RemoveFromSale(tokenId); // Notificar retiro de venta del token.
    }

    // Entonces la función removeFromSale permite al propietario de un token específico retirar ese token de la venta,
    // realizando varias verificaciones de seguridad antes de actualizar el estado del token y emitiendo un evento para notificar el cambio. 
    // Utilizamos funciones auxiliares para manipular listas y encontrar valores dentro de ellas.



    // SETTERS

// Utilización del token ERC20 para transacciones.
    function setFundsToken(address token) external onlyOwner { // Parámetro, token: Que va a ser la Dirección del contrato del token ERC20.                                                      
        require(token != address(0),"Invalid address"); // La dirección no puede ser la dirección cero (address(0)). Incluir un mensaje de falla.
        fundsToken = ERC20(token); // Contrato ERC20 a variable fundsToken.
    }

// Dirección para colectar los fondos de las ventas de NFTs.
    function setFundsCollector(address _address) external onlyOwner { // Parámetro, dirección de colector de fondos.
        require(_address != address(0)); // La dirección no puede ser la dirección cero (address(0))
        fundsCollector = _address; // Dirección proporcionada a la variable fundsCollector.
    }

// Dirección para colectar las tarifas de transacción.
    function setFeesCollector(address _address) external onlyOwner { // Parámetro, dirección del colector de tarifas.
        require(_address != address(0)); // La dirección no puede ser la dirección cero (address(0))
        feesCollector = _address; // Dirección proporcionada a la variable feesCollector.
    }

// Porcentaje de beneficio a pagar en las reclamaciones.
    function setProfitToPay(uint32 _profitToPay) external onlyOwner { // Parámetro, porcentaje de beneficio a pagar.
        profitToPay = _profitToPay; // Valor proporcionado a la variable profitToPay.
    }

// Función que Habilita o deshabilita la compra de NFTs.
    function setCanBuy(bool _canBuy) external onlyOwner { // Parámetro, booleano que indica si la compra está permitida.
        canBuy = _canBuy;  // Valor proporcionado a la variable canBuy.
    }

// Función que Habilita o deshabilita la reclamación de NFTs.
    function setCanClaim(bool _canClaim) external onlyOwner { // Parámetro, booleano que indica si la reclamacion está permitida.
        canClaim = _canClaim; // Valor proporcionado a la variable canClaim.
    }

// Función que Habilita o deshabilita el intercambio de NFTs.
    function setCanTrade(bool _canTrade) external onlyOwner { // Parámetro, booleano que indica si la intercambio está permitido.
        canTrade = _canTrade; // Valor proporcionado a la variable canTrade.
    }

// Valor máximo que se puede recaudar de venta de NFTs.
    function setMaxValueToRaise(uint _maxValueToRaise) external onlyOwner { // Parámetro, valor máximo a recaudar.
        maxValueToRaise = _maxValueToRaise; // Valor proporcionado a la variable maxValueToRaise.
    }
    
// Función para agregar un valor válido para NFTs.   
    function addValidValues(uint value) external onlyOwner { // Parámetro, valor que se quiere agregar como válido.
        validValues[value] = true; // Valor como válido en el mapeo validValues.
    }

// Función para eliminar un valor válido previamente agregado.
    function deleteValidValues(uint value) external onlyOwner { // Parámetro, valor que se quiere eliminar de los valores válidos.
        validValues[value] = false; // Valor como no válido en el mapeo validValues.
    }

// Función para establecer la cantidad máxima de NFTs por operación.
    function setMaxBatchCount(uint16 _maxBatchCount) external onlyOwner { // Parámetro, cantidad máxima de NFTs por operación.
        maxBatchCount = _maxBatchCount; // Valor proporcionado a la variable maxBatchCount.
    }

// Tarifa aplicada a las compras de NFTs.
    function setBuyFee(uint16 _buyFee) external onlyOwner { // Parámetro, porcentaje de tarifa para compras.
        buyFee = _buyFee; // Valor proporcionado a la variable buyFee.
    }

// Tarifa aplicada a las transacciones de NFTs.
    function setTradeFee(uint16 _tradeFee) external onlyOwner { // Parámetro, porcentaje de tarifa para transacciones.
        tradeFee = _tradeFee; // Valor proporcionado a la variable tradeFee.
    }


    
    // GETTERS


// IDs de los tokens que están disponibles para la venta.
    function getListTokensOnSale() external view returns(uint[] memory) { 
        return listTokensOnSale; // Devolver un array de enteros de la lista de IDs de tokens que están a la venta.
    }

    // RECOVER FUNDS 

// Retiro (propietario) de fondos en Ether almacenados en el contrato.
    function recover() external onlyOwner {

// Transferencia del balance completo de Ether (ETH) al propietario del contrato.
    
        (bool succes, ) = owner().call{value: address(this).balance}(""); 
        require(succes,"transfer fail");
    
       
       
    }   

// Retiro por parte del propietario de tokens ERC20.
    function recoverERC20(address token) external onlyOwner { // Parámetro, dirección del contrato del token ERC20 que se desea recuperar.
           uint256 balance = fundsToken.balanceOf(token);
           bool success = fundsToken.transfer(owner(), balance);
        require(success, "Transfer of ERC20 tokens failed.");
// Transferir el balance completo (IERC20(token).balanceOf(address(this))) al propietario (owner()).
         // Llamamos a la función transfer del contrato ERC20
       //modificada
             /*  uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
                bool success = IERC20(tokenAddress).transfer(owner(), balance);
                require(success, "Transfer of ERC20 tokens failed.");
             // Incluir un mensaje de falla.
    */  
                  // Crear instancia del contrato ERC20
        //IERC20 tokenFunds = IERC20(token);
        // Obtener el saldo del contrato actual
        
        // Transferir el saldo completo al propietario
 
    }

    // RECEIVE

// Permitir al contrato recibir Ether sin datos adicionales. 
    receive() external payable {}

    // ARRAYS

// Verificar duplicados en el array antes de agregar un nuevo valor.
    function addToArray(uint[] storage array, uint addValue) private { // Parámetro, array de enteros donde se añadirá el valor y valor que se añadirá al array.

// Posición del value en el array list usando la función find.
        uint256 index = find(array, addValue);
        if (index == array.length) { // Si el valor no está en el array, push al final del array.
            array.push(addValue);
        }
    }

// Eliminar un valor del array.
    function removeFromArray(uint256[] storage list, uint value) private { // Parámetros, array de enteros del cual se eliminará el valor y valor que se eliminara al array.
// Posición del value en el array list usando la función find.
        uint256 index = find(list, value);
        if (index != list.length) { // Si el valor está en el array, reemplazar el valor con el último valor en el array y despues reducir el tamaño del array.
            list[index] = list[list.length-1];
            list.pop();
        }
    }

// Buscar un valor en un array y retornar su índice o la longitud del array si no se encuentra.
    function find( uint256[] memory array, uint value) private pure returns(uint)  { // Parámetros, array de enteros en el cual se buscará el valor y valor que se buscará en el array..

        for (uint i = 0; i < array.length;i++) { // Retornar la posición del valor en el array. 
            if (array[i] == value) {
                return array[i];
            }
        }
        return array.length; // Si no se encuentra, retornar la longitud del array.
    }


    // NOT SUPPORTED FUNCTIONS

// Funciones para deshabilitar las transferencias de NFTs,

    function transferFrom(address, address, uint256) 
        public 
        pure
        override(ERC721, IERC721) 
    {
        revert("Not Allowed");
    }

    function safeTransferFrom(address, address, uint256) 
        public pure override(ERC721, IERC721) 
    {
        revert("Not Allowed");
    }

    function safeTransferFrom(address, address, uint256,  bytes memory) 
        public 
        pure
        override(ERC721, IERC721) 
    {
        revert("Not Allowed");
    }


    // Compliance required by Solidity

// Funciones para asegurar que el contrato cumple con los estándares requeridos por ERC721 y ERC721Enumerable.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal 
        override(ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }    
}

