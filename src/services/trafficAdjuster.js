/**
 * Dynamic Traffic Delay Adjuster (BE-3 X-Factor Deliverable)
 * Modifies ETA calculations based on historical speed and dynamic congestion factors on specific route segments.
 */

class TrafficAdjuster {
  constructor() {
    // Segment congestion rules: segmentKey -> congestion multiplier (1.0 = normal, 1.5 = 50% slower, 2.0 = double time)
    this.segmentCongestionMap = {
      // Amritsar Golden Temple route congestion
      "STOP_02-STOP_03": 1.4, // Hall Bazaar congestion
      "STOP_03-STOP_04": 1.8, // Golden Temple narrow street congestion
      // Ludhiana Clock Tower congestion
      "STOP_10-STOP_11": 1.5
    };
  }

  /**
   * Get current time-of-day traffic multiplier
   * Morning Peak: 08:00 - 10:30 (+30% delay)
   * Evening Peak: 17:00 - 20:30 (+40% delay)
   * Off Peak: 1.0 (Normal)
   */
  getTimeOfDayFactor() {
    const now = new Date();
    const hours = now.getHours();
    const minutes = now.getMinutes();
    const timeInDecimal = hours + minutes / 60;

    if (timeInDecimal >= 8.0 && timeInDecimal <= 10.5) {
      return 1.3; // Morning peak traffic
    } else if (timeInDecimal >= 17.0 && timeInDecimal <= 20.5) {
      return 1.4; // Evening peak traffic
    }
    return 1.0; // Off-peak standard speed
  }

  /**
   * Calculate adjusted travel speed for a segment
   * @param {number} baseSpeed - Base speed in km/h
   * @param {string} fromStopId - Starting stop ID
   * @param {string} toStopId - Ending stop ID
   * @returns {number} Adjusted speed in km/h
   */
  getAdjustedSpeed(baseSpeed, fromStopId, toStopId) {
    const segmentKey = `${fromStopId}-${toStopId}`;
    const reverseSegmentKey = `${toStopId}-${fromStopId}`;

    const segmentMultiplier = this.segmentCongestionMap[segmentKey] || this.segmentCongestionMap[reverseSegmentKey] || 1.0;
    const timeFactor = this.getTimeOfDayFactor();

    const totalDelayFactor = segmentMultiplier * timeFactor;
    const adjustedSpeed = Math.max(10, baseSpeed / totalDelayFactor); // Keep minimum 10 km/h baseline

    return {
      adjustedSpeed: parseFloat(adjustedSpeed.toFixed(2)),
      delayFactor: parseFloat(totalDelayFactor.toFixed(2)),
      isCongested: totalDelayFactor > 1.2
    };
  }

  /**
   * Dynamically update congestion status for a specific route segment (e.g. from crowdsourced reports or traffic sensors)
   */
  setSegmentCongestion(fromStopId, toStopId, multiplier) {
    const segmentKey = `${fromStopId}-${toStopId}`;
    this.segmentCongestionMap[segmentKey] = Math.max(0.5, Math.min(3.0, multiplier));
  }
}

module.exports = new TrafficAdjuster();

