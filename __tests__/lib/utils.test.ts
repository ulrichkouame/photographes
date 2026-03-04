import { cn, formatCurrency, formatDate } from '@/lib/utils'

describe('cn()', () => {
  it('merges class names correctly', () => {
    expect(cn('foo', 'bar')).toBe('foo bar')
  })

  it('handles conditional classes', () => {
    expect(cn('foo', false && 'bar', 'baz')).toBe('foo baz')
  })

  it('merges tailwind classes and resolves conflicts', () => {
    expect(cn('p-2', 'p-4')).toBe('p-4')
  })

  it('handles undefined and null', () => {
    expect(cn('foo', undefined, null, 'bar')).toBe('foo bar')
  })
})

describe('formatCurrency()', () => {
  it('formats numbers as XOF currency', () => {
    const result = formatCurrency(50000)
    expect(result).toContain('50')
    expect(result).toContain('000')
  })

  it('handles zero', () => {
    const result = formatCurrency(0)
    expect(result).toBeDefined()
  })
})

describe('formatDate()', () => {
  it('formats ISO date string to French locale', () => {
    const result = formatDate('2024-01-15T00:00:00Z')
    expect(result).toContain('2024')
  })

  it('returns a string', () => {
    const result = formatDate('2024-06-20T12:00:00Z')
    expect(typeof result).toBe('string')
  })
})
