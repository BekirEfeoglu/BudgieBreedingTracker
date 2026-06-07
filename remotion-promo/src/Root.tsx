import { Composition } from "remotion";
import { BudgiePromo } from "./BudgiePromo";
import { BudgieReels } from "./BudgieReels";
import { timing, timingReels } from "./theme";

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="BudgiePromo"
        component={BudgiePromo}
        durationInFrames={timing.totalDuration}
        fps={timing.fps}
        width={1920}
        height={1080}
      />
      <Composition
        id="BudgieReels"
        component={BudgieReels}
        durationInFrames={timingReels.totalDuration}
        fps={timingReels.fps}
        width={1080}
        height={1920}
      />
    </>
  );
};
