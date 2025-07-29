import React from "react";

const Hero: React.FC = () => {
  const competitions = [
    { title: "Crypto Bull Run", description: "12 spots left" },
    { title: "DeFi Masters", description: "8 spots left" },
    { title: "NFT Predictors", description: "5 spots left" },
  ];

  return (
    <div className="flex items-center justify-between flex-col md:flex-row pt-10 w-full px-5">
      {/* Left Section */}
      <div className="text-center md:text-left mb-8 md:mb-0 md:w-1/2 px-4">
        <h1 className="text-4xl font-bold mb-4">Fantasy Investing With Your ETH Token Stakes</h1>
        <p className="text-lg mb-6">
          Stake your own ETH tokens to join competitive investment solutions. Predict market movements, compete with
          others, and win bigger token rewards.
        </p>
        <div className="flex justify-center md:justify-start space-x-4">
          <button className="bg-green-500 text-white px-6 py-2 rounded-full">Get Started</button>
          <button className="bg-purple-500 text-white px-6 py-2 rounded-full">Learn More</button>
        </div>
      </div>

      {/* Right Section - Card */}
      <div className="bg-base-100 p-6 rounded-2xl shadow-lg text-center md:w-1/2 px-4">
        <h2 className="text-4xl font-bold text-green-500">30+</h2>
        <h2 className="text-xl font-semibold mb-4">Active Competitions</h2>
        <div className="flex justify-center space-x-4">
          {competitions.map((comp, index) => (
            <div key={index} className="bg-base-200 p-4 rounded-lg w-1/3">
              <span className="bg-green-500 text-white text-xs px-2 py-1 rounded-full absolute -top-2 -left-2">
                LIVE
              </span>
              <h3 className="font-medium">{comp.title}</h3>
              <p className="text-sm text-gray-500">{comp.description}</p>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default Hero;
