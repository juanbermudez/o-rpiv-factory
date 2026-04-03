/**
 * Compute execution waves from a dependency graph.
 * Tasks in the same wave have all dependencies resolved and can run in parallel.
 */
export interface DependencyGraph {
  [taskId: string]: {
    blocks: string[];
    blockedBy: string[];
  };
}

export interface Wave {
  wave: number;
  tasks: string[];
  parallel: boolean;
}

export function computeWaves(graph: DependencyGraph): Wave[] {
  const waves: Wave[] = [];
  const completed = new Set<string>();
  const allTasks = Object.keys(graph);
  let waveNumber = 0;

  while (completed.size < allTasks.length) {
    waveNumber++;
    const ready = allTasks.filter(
      taskId =>
        !completed.has(taskId) &&
        graph[taskId].blockedBy.every(dep => completed.has(dep))
    );

    if (ready.length === 0) {
      const remaining = allTasks.filter(t => !completed.has(t));
      throw new Error(
        `Circular dependency detected. Remaining tasks: ${remaining.join(", ")}`
      );
    }

    waves.push({
      wave: waveNumber,
      tasks: ready,
      parallel: ready.length > 1,
    });

    ready.forEach(t => completed.add(t));
  }

  return waves;
}
