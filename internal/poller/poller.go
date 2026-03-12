package poller

import (
	"context"
	"fmt"
	"os"
	"time"

	gh "github.com/mrymam/ghv/pkg/github"
)

// PR is a JSON-friendly representation of a GitHub PR for NDJSON output.
type PR struct {
	Repo      string    `json:"repo"`
	FullRepo  string    `json:"full_repo"`
	Number    int       `json:"number"`
	Title     string    `json:"title"`
	Author    string    `json:"author"`
	URL       string    `json:"url"`
	UpdatedAt time.Time `json:"updated_at"`
	Draft     bool      `json:"draft"`
}

type Event struct {
	Type      string    `json:"type"`
	PR        *PR       `json:"pr,omitempty"`
	URL       string    `json:"url,omitempty"`
	Count     int       `json:"count"`
	Timestamp time.Time `json:"timestamp"`
}

type Poller struct {
	Username string
	OrgQ     string
	Interval time.Duration
}

func toPR(p gh.PR) PR {
	return PR{
		Repo:      p.RepoName(),
		FullRepo:  p.FullRepoName(),
		Number:    p.Number,
		Title:     p.Title,
		Author:    p.User.Login,
		URL:       p.HTMLURL,
		UpdatedAt: p.UpdatedAt,
		Draft:     p.Draft,
	}
}

func (p *Poller) Run(ctx context.Context) <-chan Event {
	ch := make(chan Event)

	go func() {
		defer close(ch)

		// Initial fetch
		prs, err := p.fetchReviewRequests()
		known := make(map[string]PR)
		if err == nil {
			for _, pr := range prs {
				known[pr.URL] = pr
			}
		}

		ch <- Event{
			Type:      "init",
			Count:     len(known),
			Timestamp: time.Now(),
		}

		ticker := time.NewTicker(p.Interval)
		defer ticker.Stop()

		for {
			select {
			case <-ctx.Done():
				return
			case <-ticker.C:
				prs, err := p.fetchReviewRequests()
				if err != nil {
					fmt.Fprintf(os.Stderr, "poll error: %v\n", err)
					continue
				}

				current := make(map[string]PR)
				for _, pr := range prs {
					current[pr.URL] = pr
					if _, exists := known[pr.URL]; !exists {
						ch <- Event{
							Type:      "new",
							PR:        &pr,
							Count:     len(current),
							Timestamp: time.Now(),
						}
					}
				}

				for url := range known {
					if _, exists := current[url]; !exists {
						ch <- Event{
							Type:      "removed",
							URL:       url,
							Count:     len(current),
							Timestamp: time.Now(),
						}
					}
				}

				known = current

				ch <- Event{
					Type:      "poll",
					Count:     len(current),
					Timestamp: time.Now(),
				}
			}
		}
	}()

	return ch
}

func (p *Poller) fetchReviewRequests() ([]PR, error) {
	qualifier := fmt.Sprintf("review-requested:%s%s", p.Username, p.OrgQ)
	ghPRs, err := gh.SearchPRs(qualifier)
	if err != nil {
		return nil, err
	}
	prs := make([]PR, len(ghPRs))
	for i, pr := range ghPRs {
		prs[i] = toPR(pr)
	}
	return prs, nil
}
