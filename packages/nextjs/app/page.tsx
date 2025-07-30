"use client";

import type { NextPage } from "next";
import Hero from "~~/components/HeroSection";
import HowItWorks from "~~/components/HowItWorks";
import PlatformFeatures from "~~/components/PlatformFeatures";
import ReadyToJoin from "~~/components/ReadyToJoin";
import StatsOverview from "~~/components/StatsOverview";

const Home: NextPage = () => {
  return (
    <>
      {/* Hero Section */}
      <Hero />

      {/* Stats Overview */}
      <StatsOverview />

      {/* Platform Features */}
      <PlatformFeatures />

      {/* How It Works */}
      <HowItWorks />

      {/* Ready to Join CTA */}
      <ReadyToJoin />
    </>
  );
};

export default Home;
