package service

import "testing"

func TestResolveUpdateRepositoryUsesDefault(t *testing.T) {
	t.Setenv(updateRepositoryEnv, "")

	repository, err := resolveUpdateRepository()
	if err != nil {
		t.Fatalf("resolveUpdateRepository() error = %v", err)
	}
	if repository != defaultGitHubRepo {
		t.Fatalf("resolveUpdateRepository() = %q, want %q", repository, defaultGitHubRepo)
	}
}

func TestResolveUpdateRepositoryUsesConfiguredRepository(t *testing.T) {
	t.Setenv(updateRepositoryEnv, "lzy98276/sub2api")

	repository, err := resolveUpdateRepository()
	if err != nil {
		t.Fatalf("resolveUpdateRepository() error = %v", err)
	}
	if repository != "lzy98276/sub2api" {
		t.Fatalf("resolveUpdateRepository() = %q, want %q", repository, "lzy98276/sub2api")
	}
}

func TestResolveUpdateRepositoryRejectsInvalidValue(t *testing.T) {
	t.Setenv(updateRepositoryEnv, "https://github.com/lzy98276/sub2api")

	if _, err := resolveUpdateRepository(); err == nil {
		t.Fatal("resolveUpdateRepository() error = nil, want invalid repository error")
	}
}
