# Interface Building Guide

Default stack: **TypeScript + Next.js + RainbowKit + wagmi + viem**

## Project Setup

```bash
npx create-next-app@latest my-glue-app --typescript
cd my-glue-app
npm i @rainbow-me/rainbowkit wagmi viem @tanstack/react-query
```

## Core Configuration

### wagmi.config.ts

```typescript
import { http, createConfig } from 'wagmi';
import { mainnet, sepolia, base, optimism } from 'wagmi/chains';
import { getDefaultConfig } from '@rainbow-me/rainbowkit';

export const config = getDefaultConfig({
  appName: 'My Glue App',
  projectId: 'YOUR_WALLETCONNECT_PROJECT_ID',
  chains: [mainnet, base, optimism, sepolia],
  transports: {
    [mainnet.id]: http(),
    [base.id]: http(),
    [optimism.id]: http(),
    [sepolia.id]: http(),
  },
});
```

### app/providers.tsx

```typescript
'use client';
import { RainbowKitProvider } from '@rainbow-me/rainbowkit';
import { WagmiProvider } from 'wagmi';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { config } from '../wagmi.config';
import '@rainbow-me/rainbowkit/styles.css';

const queryClient = new QueryClient();

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider>
          {children}
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}
```

### app/layout.tsx

```typescript
import { Providers } from './providers';

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
```

## Component Pattern

```typescript
'use client';
import { useAccount, useContractWrite, useContractRead } from 'wagmi';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import { parseEther } from 'viem';

const CONTRACT_ADDRESS = '0x...'; // Deployed contract address
const ABI = [...]; // Contract ABI from compilation

export function InteractPanel() {
  const { address, isConnected } = useAccount();

  const { data: balance } = useContractRead({
    address: CONTRACT_ADDRESS,
    abi: ABI,
    functionName: 'balanceOf',
    args: [address],
    enabled: !!address,
  });

  const { write: unglue, isLoading } = useContractWrite({
    address: CONTRACT_ADDRESS,
    abi: ABI,
    functionName: 'unglue',
  });

  const handleUnglue = () => {
    if (!address) return;
    unglue({
      args: [
        ['0x...'], // collaterals array
        parseEther('100'), // amount to burn
        address, // recipient
      ],
    });
  };

  return (
    <div>
      <ConnectButton />
      {isConnected && (
        <>
          <p>Balance: {balance?.toString()}</p>
          <button onClick={handleUnglue} disabled={isLoading}>
            {isLoading ? 'Processing...' : 'Unglue'}
          </button>
        </>
      )}
    </div>
  );
}
```

## After Getting Deployed Addresses

1. Update `CONTRACT_ADDRESS` in components
2. Import ABI from `artifacts/contracts/YourContract.sol/YourContract.json`
3. Test all interactions on testnet first

## Interface Deployment (Vercel)

### Step-by-step:

1. **Prep:** Ensure Next.js app works locally with `npm run dev`
2. **Build:** `npm run build` — fix any errors
3. **Install Vercel CLI:** `npm i -g vercel`
4. **Login:** `vercel login`
5. **Deploy:** `vercel` — follow prompts
6. **Environment Variables:** Vercel dashboard → Settings → Environment Variables → add all `.env.local` vars
7. **Custom domain (optional):** Vercel dashboard → Domains → add your domain
8. **Supabase (if needed):** Create Supabase project → get URL + ANON_KEY → add to Vercel env → redeploy

### .env.local

```
NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID=your_project_id
NEXT_PUBLIC_CONTRACT_ADDRESS=0x...
```
