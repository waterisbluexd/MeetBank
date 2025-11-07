const functions = require("firebase-functions");
const admin = require("firebase-admin");
const {VertexAI} = require("@google-cloud/vertexai");

// Initialize Firebase and Vertex AI
admin.initializeApp();
const vertexAI = new VertexAI({
  project: process.env.GCLOUD_PROJECT,
  location: "us-central1",
});
const generativeModel = vertexAI.getGenerativeModel({
  model: "gemini-1.0-pro",
});

/**
 * A callable Cloud Function that takes meeting text as input and
 * returns an AI-generated summary using the Gemini API.
 */
exports.summarizeMeeting = functions.https.onCall(async (data, context) => {
  // Best practice: ensure the user is authenticated.
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "The function must be called while authenticated.",
    );
  }

  const text = data.text;
  if (!text || typeof text !== "string") {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "The function must be called with a 'text' argument.",
    );
  }

  // The prompt for the Gemini API.
  const prompt = `Summarize the following meeting notes concisely, ` +
    `focusing on key decisions and action items: \n\n${text}`;

  try {
    // Call the Gemini API
    const resp = await generativeModel.generateContent(prompt);
    const response = resp.response;
    const summary = response.candidates[0].content.parts[0].text;

    // Return the summary to the Flutter app
    return {summary: summary};
  } catch (error) {
    console.error("Error calling Gemini API:", error);
    throw new functions.https.HttpsError(
        "internal",
        "Failed to generate summary.",
        error,
    );
  }
});
