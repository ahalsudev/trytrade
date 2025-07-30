import React from "react";

const HowItWorks: React.FC = () => {
  const steps = [
    {
      no: 1,
      title: "Connect Wallet",
      description: "Connect your Cryptocurrency wallet to authenticate and participate.",
    },
    {
      no: 2,
      title: "Stake & Join",
      description: "Stake your ETH tokens to join competitions or create your own custom parameters.",
    },
    {
      no: 3,
      title: "Make Predictions",
      description: "Predict price movements of cryptocurrencies within competition timeframe.",
    },
    {
      no: 4,
      title: "Win Rewards",
      description: "Claim your rewards automatically when you outperform other participants.",
    },
  ];

  return (
    <div className="flex items-center flex-col grow pt-10 px-5">
      <h1 className="text-center text-4xl font-bold mb-6">How It Works</h1>
      <p className="text-center text-lg mb-12">Start your journey into fantasy in just a few steps</p>
      <div className="flex flex-col md:flex-row justify-start items-start gap-8">
        {steps.map((step, index) => (
          <div key={index} className="bg-base-100 p-6 rounded-lg w-full md:w-1/4 text-left">
            <h3 className="text-2xl font-bold mb-2">0{step.no}</h3>
            <h4 className="text-lg font-medium mb-2">{step.title}</h4>
            <p className="text-base">{step.description}</p>
          </div>
        ))}
      </div>
    </div>
  );
};

export default HowItWorks;
