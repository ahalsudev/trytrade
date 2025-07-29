import React from "react";
import { BugAntIcon, CogIcon, MagnifyingGlassIcon } from "@heroicons/react/24/outline";

const PlatformFeatures: React.FC = () => {
  const features = [
    {
      icon: <CogIcon className="h-8 w-8 fill-secondary" />,
      title: "Smart Predictions",
      description: "Predict price movement of cryptocurrencies with various time horizons and compete with others.",
    },
    {
      icon: <BugAntIcon className="h-8 w-8 fill-secondary" />,
      title: "Blockchain Secured",
      description: "All competitions and rewards are secured by smart contracts on the ETH Network.",
    },
    {
      icon: <MagnifyingGlassIcon className="h-8 w-8 fill-secondary" />,
      title: "Real ETH Token Rewards",
      description: "Stake your ETH tokens to enter and win bigger rewards by outperforming other participants.",
    },
  ];

  return (
    <div className="flex items-center flex-col grow pt-10 px-5">
      <h1 className="text-center text-4xl font-bold mb-6">Platform Features</h1>
      <p className="text-center text-lg mb-12">
        A complete ecosystem for fantasy investing competitions on the blockchain
      </p>
      <div className="flex justify-center items-center gap-12 flex-col md:flex-row">
        {features.map((feature, index) => (
          <div
            key={index}
            className="flex flex-col bg-base-100 px-10 py-10  items-center max-w-xs rounded-3xl relative"
          >
            <div className="absolute top-4 left-4">
              <div className="w-12 h-12 rounded-full bg-base-200 flex items-center justify-center">{feature.icon}</div>
            </div>
            <div className="mt-12">
              <h3 className="font-medium text-lg mb-2">{feature.title}</h3>
              <p>{feature.description}</p>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default PlatformFeatures;
