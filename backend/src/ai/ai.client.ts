// interface
export interface AIClient {
  infer(input: { age: number; gender: 'male'|'female'|'other'; history?: string; symptoms: string }):
    Promise<{ risk_score: number; risk_label: 'Thấp'|'Trung bình'|'Cao'; suggestion?: string }>;
}