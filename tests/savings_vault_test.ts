import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Allows valid deposits",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('savings_vault', 'deposit', [
                types.uint(5000)
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk().expectBool(true);
        
        // Verify balance
        let balanceBlock = chain.mineBlock([
            Tx.contractCall('savings_vault', 'get-balance', [
                types.principal(wallet1.address)
            ], wallet1.address)
        ]);
        
        balanceBlock.receipts[0].result.expectOk().expectUint(5000);
    }
});

Clarinet.test({
    name: "Rejects deposits below minimum",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('savings_vault', 'deposit', [
                types.uint(500)
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectErr().expectUint(102); // err-invalid-amount
    }
});

Clarinet.test({
    name: "Allows withdrawals with interest",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        // First deposit
        let depositBlock = chain.mineBlock([
            Tx.contractCall('savings_vault', 'deposit', [
                types.uint(10000)
            ], wallet1.address)
        ]);
        
        // Advance blocks to accrue interest
        chain.mineEmptyBlockUntil(100);
        
        // Withdraw full amount
        let withdrawBlock = chain.mineBlock([
            Tx.contractCall('savings_vault', 'withdraw', [
                types.uint(10000)
            ], wallet1.address)
        ]);
        
        withdrawBlock.receipts[0].result.expectOk().expectBool(true);
    }
});

Clarinet.test({
    name: "Only owner can update interest rate",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('savings_vault', 'update-interest-rate', [
                types.uint(600)
            ], deployer.address),
            
            Tx.contractCall('savings_vault', 'update-interest-rate', [
                types.uint(700)
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk().expectBool(true);
        block.receipts[1].result.expectErr().expectUint(100); // err-owner-only
    }
});