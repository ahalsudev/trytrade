import React from "react";

const ReadyToJoin: React.FC = () => {
  return (
    <div className="flex items-center flex-col grow pt-10 px-5 text-center">
      <h1 className="text-4xl font-bold mb-6">Ready to Join FantasyInvest?</h1>
      <p className="text-lg mb-8">
        Start staking your tokens today in fantasy competitions and earn bigger rewards when you win
      </p>
      <button className="bg-green-500 text-white px-6 py-2 rounded-full">Get Started Now</button>
    </div>
  );
};

export default ReadyToJoin;
