// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/BUSD.sol";
import "../src/CCNFT.sol";
import { DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";
// Definición del contrato de prueba CCNFTTest que hereda de Test. 
// Declaración de direcciones y dos instancias de contratos (BUSD y CCNFT).
contract CCNFTTest is Test {
    address deployer;
    address c1;
    address c2;
    address funds;
    address fees;
    BUSD busd;
    CCNFT ccnft;

// Ejecución antes de cada prueba. 
// Inicializar las direcciones y desplgar las instancias de BUSD y CCNFT.
    function setUp() public {
        deployer = vm.addr(1); // Usa la cuenta 1 de Anvil
        c1 = vm.addr(2);
        c2 = vm.addr(3);
        funds = vm.addr(4);
        fees = vm.addr(5);
        
        vm.startPrank(deployer);
        
        busd = new BUSD();
        //address busdAddress = DevOpsTools.get_most_recent_deployment("basicNFT", block.chainid);
        ccnft = new CCNFT();
        
        assertEq(ccnft.owner(), deployer, "Deployer should be the owner of CCNFT");
        
        busd.approve(address(ccnft), 1000 * 10 ** 18);
      
       
        
        vm.stopPrank();

    }

// Prueba de "setFundsCollector" del contrato CCNFT. 
// Llamar al método y despues verificar que el valor se haya establecido correctamente.
    function testSetFundsCollector() public {
         vm.prank(deployer);
        ccnft.setFundsCollector(funds);
        assertEq(ccnft.fundsCollector(), funds, "Funds collector address was not set correctly");
    }

// Prueba de "setFeesCollector" del contrato CCNFT
// Verificar que el valor se haya establecido correctamente.
    function testSetFeesCollector() public {
        vm.prank(deployer);
        ccnft.setFeesCollector(fees);
        assertEq(ccnft.feesCollector(), fees, "Funds collector address was not set correctly");
    }

// Prueba de "setProfitToPay" del contrato CCNFT
// Verificar que el valor se haya establecido correctamente.
    function testSetProfitToPay() public {
         vm.prank(deployer);
        ccnft.setProfitToPay(1);
        assertEq(ccnft.profitToPay(), 1, "Profit was not set correctly");
    }

// Prueba de "setCanBuy" primero estableciéndolo en true y verificando que se establezca correctamente.
// Despues establecerlo en false verificando nuevamente.
    function testSetCanBuy() public {
        vm.prank(deployer);
        ccnft.setCanBuy(true);
        assertEq(ccnft.canBuy(), true, "Can Buy was not set correctly");
    }

// Prueba de método "setCanTrade". Similar a "testSetCanBuy".
    function testSetCanTrade() public {
         vm.prank(deployer);
        ccnft.setCanTrade(true);
        assertEq(ccnft.canTrade(), true, "Can Trade was not set correctly");
    }

// Prueba de método "setCanClaim". Similar a "testSetCanBuy".
    function testSetCanClaim() public {
         vm.prank(deployer);
        ccnft.setCanClaim(true);
        assertEq(ccnft.canClaim(), true, "Can Claim was not set correctly");
    }

// Prueba de "setMaxValueToRaise" con diferentes valores.
// Verifica que se establezcan correctamente.
    function testSetMaxValueToRaise() public {
        vm.prank(deployer);
        ccnft.setMaxValueToRaise(10000000000000000000000000);
        assertEq(ccnft.maxValueToRaise(),10000000000000000000000000 , "Max Value to raise wasn't set correctly");
    }

// Prueba de "addValidValues" añadiendo diferentes valores.
// Verificar que se hayan añadido correctamente.
    function testAddValidValues() public {
        vm.prank(deployer);
        ccnft.addValidValues(100000000000000000000000);
        assertEq(ccnft.validValues(100000000000000000000000),true, "Value not added");
    }

// Prueba de "deleteValidValues" añadiendo y luego eliminando un valor.
// Verificar que la eliminación se haya realizado correctamente.
    function testDeleteValidValues() public {
        vm.prank(deployer);
        ccnft.addValidValues(100000000000000000000000);
        assertEq(ccnft.validValues(100000000000000000000000),true, "Value not added");
        vm.prank(deployer);
        ccnft.deleteValidValues(100000000000000000000000);
        assertEq(ccnft.validValues(100000000000000000000000),false, "Cant't delete this value");
    }

// Prueba de "setMaxBatchCount".
// Verifica que el valor se haya establecido correctamente.
    function testSetMaxBatchCount() public {
        vm.prank(deployer);
        ccnft.setMaxBatchCount(10);
        assertEq(ccnft.maxBatchCount(),10, "Max Batch count not added");

    }

// Prueba de "setBuyFee".
// Verificar que el valor se haya establecido correctamente.
    function testSetBuyFee() public {
        vm.prank(deployer);
        ccnft.setBuyFee(10);
        assertEq(ccnft.buyFee(),10, "Buy Fee not added");
    }

// Prueba de "setTradeFee".
// Verificar que el valor se haya establecido correctamente.
    function testSetTradeFee() public {
        vm.prank(deployer);
        ccnft.setTradeFee(10);
        assertEq(ccnft.tradeFee(),10, "Trade fee not added");

    }

// Prueba de que no se pueda comerciar cuando canTrade es false.
// Verificar que se lance un error esperado.
    function testCannotTradeWhenCanTradeIsFalse() public {
        vm.prank(deployer);
        ccnft.setCanTrade(false);
        vm.expectRevert("Can't trade this token");
        vm.prank(c1);
        ccnft.trade(0);
    }

// Prueba que no se pueda comerciar con un token que no existe, incluso si canTrade es true. 
// Verificar que se lance un error esperado.
    function testCannotTradeWhenTokenDoesNotExist() public {
        vm.prank(deployer);
        ccnft.setCanTrade(true);
        vm.expectRevert("Token dont exist");
        vm.prank(c1);
        ccnft.trade(0);
    }
}
