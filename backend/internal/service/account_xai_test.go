package service

import "testing"

func TestXAIAccountDefaultsToOfficialBaseURL(t *testing.T) {
	account := &Account{
		Platform:    PlatformXAI,
		Type:        AccountTypeAPIKey,
		Credentials: map[string]any{"api_key": "xai-test"},
	}

	if got := account.GetOpenAIBaseURL(); got != "https://api.x.ai" {
		t.Fatalf("GetOpenAIBaseURL() = %q, want %q", got, "https://api.x.ai")
	}
	if got := account.GetOpenAIApiKey(); got != "xai-test" {
		t.Fatalf("GetOpenAIApiKey() = %q, want %q", got, "xai-test")
	}
}

func TestXAIAccountSupportsChatCompletionsOnly(t *testing.T) {
	account := &Account{Platform: PlatformXAI, Type: AccountTypeAPIKey}

	if !account.SupportsOpenAIEndpointCapability(OpenAIEndpointCapabilityChatCompletions) {
		t.Fatal("xAI API key account should support chat completions")
	}
	if account.SupportsOpenAIEndpointCapability(OpenAIEndpointCapabilityEmbeddings) {
		t.Fatal("xAI API key account should not advertise embeddings support")
	}
}
