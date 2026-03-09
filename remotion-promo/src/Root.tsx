import { Composition } from "remotion";
import { BudgiePromo } from "./BudgiePromo";
import { timing } from "./theme";

export const RemotionRoot: React.FC = () => {
  return (
    <Composition
      id="BudgiePromo"
      component={BudgiePromo}
      durationInFrames={timing.totalDuration}
      fps={timing.fps}
      width={1920}
      height={1080}
    />
  );
};
