// src/triage/ai/rulebased.ai.client.ts
import { TriageRequestDto } from '../triage/dto/triage-request.dto';

type InferResult = {
  risk_score: number;           // 0..1
  risk_label: 'Thấp' | 'Trung bình' | 'Cao';
  suggestion?: string;
};

const SPECIALTY_MAP: Record<string, { specialty: string; weight: number; note?: string }> = {
  // Tim mạch
  'đau ngực':        { specialty: 'Tim mạch',      weight: 0.85, note: 'nguy cơ thiếu máu cơ tim' },
  'khó thở':         { specialty: 'Tim mạch',      weight: 0.8  },
  'hồi hộp':         { specialty: 'Tim mạch',      weight: 0.6  },
  'phù chân':        { specialty: 'Tim mạch',      weight: 0.55 },

  // Hô hấp
  'ho ra máu':       { specialty: 'Hô hấp',        weight: 0.9  },
  'khò khè':         { specialty: 'Hô hấp',        weight: 0.6  },
  'ho kéo dài':      { specialty: 'Hô hấp',        weight: 0.55 },

  // Thần kinh
  'đau đầu':         { specialty: 'Thần kinh',     weight: 0.5  },
  'co giật':         { specialty: 'Thần kinh',     weight: 0.9  },
  'yếu liệt':        { specialty: 'Thần kinh',     weight: 0.95, note: 'nghi đột quỵ' },
  'méo miệng':       { specialty: 'Thần kinh',     weight: 0.95 },

  // Tiêu hoá
  'đau bụng':        { specialty: 'Tiêu hoá',      weight: 0.55 },
  'nôn ói':          { specialty: 'Tiêu hoá',      weight: 0.6  },
  'tiêu chảy':       { specialty: 'Tiêu hoá',      weight: 0.5  },
  'nôn ra máu':      { specialty: 'Tiêu hoá',      weight: 0.9  },

  // Nhiễm trùng
  'sốt cao':         { specialty: 'Nhiễm',         weight: 0.6  },
  'ớn lạnh':         { specialty: 'Nhiễm',         weight: 0.55 },
  'nhiễm trùng':     { specialty: 'Nhiễm',         weight: 0.7  },

  // Chấn thương
  'chấn thương':     { specialty: 'Chấn thương',   weight: 0.6  },
  'gãy xương':       { specialty: 'Chấn thương',   weight: 0.85 },

  // Răng hàm mặt
  'sâu răng':        { specialty: 'Răng hàm mặt',  weight: 0.4  },
  'đau răng':        { specialty: 'Răng hàm mặt',  weight: 0.5  },
  'sưng nướu':       { specialty: 'Răng hàm mặt',  weight: 0.55 },

  // Sản phụ khoa
  'trễ kinh':        { specialty: 'Sản phụ khoa',  weight: 0.5  },
  'ra huyết âm đạo': { specialty: 'Sản phụ khoa',  weight: 0.7  },
  'đau bụng dưới':   { specialty: 'Sản phụ khoa',  weight: 0.55 },

  // Da liễu
  'phát ban':        { specialty: 'Da liễu',       weight: 0.45 },
  'ngứa':            { specialty: 'Da liễu',       weight: 0.35 },
  'mụn mủ':          { specialty: 'Da liễu',       weight: 0.5  },

  // Tiết niệu
  'tiểu buốt':       { specialty: 'Tiết niệu',     weight: 0.55 },
  'tiểu máu':        { specialty: 'Tiết niệu',     weight: 0.8  },

  // Mắt
  'đau mắt':         { specialty: 'Mắt',           weight: 0.5  },
  'mờ mắt':          { specialty: 'Mắt',           weight: 0.65 },

  // Tai mũi họng
  'đau họng':        { specialty: 'Tai mũi họng',  weight: 0.45 },
  'ngạt mũi':        { specialty: 'Tai mũi họng',  weight: 0.35 },
  'ù tai':           { specialty: 'Tai mũi họng',  weight: 0.4  },

  // Cơ xương khớp
  'đau khớp':        { specialty: 'Cơ xương khớp', weight: 0.5  },
  'sưng khớp':       { specialty: 'Cơ xương khớp', weight: 0.55 },

  // Tâm lý
  'mất ngủ':         { specialty: 'Tâm lý',        weight: 0.45 },
  'lo âu':           { specialty: 'Tâm lý',        weight: 0.45 },
};

function clamp01(x: number) { return Math.max(0, Math.min(1, x)); }

function labelFromScore(s: number): InferResult['risk_label'] {
  if (s >= 0.7) return 'Cao';
  if (s >= 0.4) return 'Trung bình';
  return 'Thấp';
}

function urgencyHint(label: InferResult['risk_label']): string {
  if (label === 'Cao') return 'Ưu tiên đặt trong 24h';
  if (label === 'Trung bình') return 'Nên đặt trong 72h';
  return 'Có thể đặt lịch phù hợp trong tuần';
}

export class RuleBasedAIClient {
  async infer(input: TriageRequestDto): Promise<InferResult> {
    const txt = `${input.history ?? ''} ${input.symptoms}`.toLowerCase();

    // điểm nền theo tuổi
    let score = 0;
    if (input.age >= 65) score += 0.15;
    else if (input.age >= 45) score += 0.08;

    // cộng dồn theo keyword
    const hits: { spec: string; weight: number }[] = [];
    for (const key of Object.keys(SPECIALTY_MAP)) {
      if (txt.includes(key)) {
        const { specialty, weight } = SPECIALTY_MAP[key];
        hits.push({ spec: specialty, weight });
        // cộng mềm (để tránh 1 keyword quá mạnh đè hết)
        score += weight * 0.5;
      }
    }

    // giới hạn và làm mượt
    score = clamp01(score);
    // nếu có nhiều keyword nguy cơ cao, boost nhẹ
    const highHits = hits.filter(h => h.weight >= 0.8).length;
    if (highHits >= 2) score = clamp01(score + 0.1);

    const label = labelFromScore(score);

    // gợi ý chuyên khoa thường gặp nhất trong các hit
    let suggestion: string | undefined;
    if (hits.length) {
      const tally = new Map<string, number>();
      hits.forEach(h => tally.set(h.spec, (tally.get(h.spec) ?? 0) + 1));
      const top = [...tally.entries()].sort((a, b) => b[1] - a[1])[0][0];
      suggestion = `${urgencyHint(label)} với BS chuyên khoa ${top}`;
    } else {
      suggestion = urgencyHint(label);
    }

    return { risk_score: score, risk_label: label, suggestion };
  }
}
