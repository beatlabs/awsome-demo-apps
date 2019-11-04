# Create a new chart based on our base-chart

We will use our `base-chart` as a scaffold. In order to do that we first have to copy it to a helm specific directory called `starters`:

```
mkdir -p ~/.helm/starters
cp -r base-chart/ ~/.helm/starters/base-chart
```

This chart can now be used with the `-p` flag to crate a new helm chart based on that:

```
helm create -p base-chart name-of-our-chart
```
