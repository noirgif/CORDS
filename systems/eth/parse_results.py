import os

# go through all directories in results/
# and parse the checker.log files
for dir in os.listdir('results'):

        checker_log = os.path.join('results', dir, 'checker.log')
        if not os.path.isfile(checker_log):
                continue

        results = []

        with open(checker_log, 'r') as f:
                node_no = 0
                for line in f:
                        if node_no != 0:
                                if line.startswith('transaction data verified'):
                                        results.append(True)
                                else:
                                        results.append(False)

                        if line.startswith('Testing node'):
                                node_no = int(line.split()[-1][:-1])
                        else:
                                node_no = 0
                
        print(checker_log, *results, sep=',')