import { useQuery, useQueryClient } from "@tanstack/reac-query";
import { userCallback, useMemo } from "react";

function useLocalStorage(key: string) {
 const queryKey =  useMemo(() => ['local-storage', key], [key]);

 const queryClient = useQueryClient();

  const q = useQuery({
    queryKey,
    queryFn: () => localStorage.getItem(key);
  });

  const setValue = userCallback(
    (value: string) => {
        localStorage.setItem(key, value);
        queryClient.setQueryData(queryKey, value);
    },
    [key, queryClient, queryKey]
  );

  return [q, setValue] as const;
};
