export type WordSummary = {
  id: number;
  word: string;
  definition: string;
  previewDefinition: string;
  isBookmarked: boolean;
};

export type WordDetail = {
  id: number;
  word: string;
  definition: string;
  isBookmarked: boolean;
};
