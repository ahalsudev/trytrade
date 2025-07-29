import React from "react";

const StatsOverview: React.FC = () => {
  const stats = [
    { title: "$1M+", description: "Total Volume" },
    { title: "2500+", description: "Users" },
    { title: "350+", description: "Competitions" },
    { title: "98%", description: "Secure Payouts" },
  ];

  return (
    <div className="bg-base-200 w-full py-12 px-5">
      <div className="max-w-7xl mx-auto bg-base-100 p-8 rounded-lg shadow-lg">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
          {stats.map((stat, index) => (
            <div key={index} className="text-center">
              <h1 className="text-4xl font-bold mb-2">{stat.title}</h1>
              <p className="text-lg">{stat.description}</p>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default StatsOverview;
