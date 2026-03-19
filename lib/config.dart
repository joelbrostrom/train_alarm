const trafikverketApiKey = String.fromEnvironment(
  'TRAFIKVERKET_API_KEY',
  defaultValue: 'a80f541f5d804074a52b91197f484d36',
);

const trafikverketEndpoint =
    'https://api.trafikinfo.trafikverket.se/v2/data.json';

const defaultAlertMinutes = 5;

const locationPollIntervalMs = 5000;
const positionBufferSize = 5;

// Average train speed fallback (km/h) when we can't estimate from GPS
const fallbackTrainSpeedKmh = 80.0;

// Minimum distance (meters) that always triggers alarm regardless of ETA
const minimumTriggerDistanceMeters = 500.0;
